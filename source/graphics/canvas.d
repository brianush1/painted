module graphics.canvas;
import painted.utils;
import cairo.Context;
import cairo.ImageSurface;
import cairo.Pattern;
import cairo.Matrix;
import gdk.Cairo;
import std.math;

struct Subpath {
	double startX, startY;
	double[6][] lines;
	bool closed;
}

final class Path {

	private double atX = 0, atY = 0;

	private Subpath[] subpaths;
	private bool editingSubpath = false;

	const(Subpath)[] getSubpaths() const {
		return subpaths;
	}

	bool empty() const @property {
		foreach (subpath; subpaths) {
			if (subpath.lines.length > 0) {
				return false;
			}
		}
		return true;
	}

	void closePath() {
		if (editingSubpath) {
			subpaths[$ - 1].closed = true;
			editingSubpath = false;
		}
	}

	void moveTo(double x, double y) {
		editingSubpath = false;
		atX = x;
		atY = y;
	}

	void bezierCurveTo(double c1x, double c1y, double c2x, double c2y, double x, double y) {
		if (!editingSubpath) {
			Subpath subpath;
			subpath.startX = atX;
			subpath.startY = atY;
			subpath.lines = [[c1x, c1y, c2x, c2y, x, y]];
			subpaths.assumeSafeAppend ~= subpath;
			editingSubpath = true;
		}
		else {
			subpaths[$ - 1].lines.assumeSafeAppend ~= [c1x, c1y, c2x, c2y, x, y];
		}
		atX = x;
		atY = y;
	}

	void lineTo(double x, double y) {
		bezierCurveTo(atX, atY, x, y, x, y);
	}

	void clear() {
		subpaths = [];
		editingSubpath = false;
		atX = 0;
		atY = 0;
	}

	void rectangle(double x, double y, double w, double h) {
		moveTo(x, y);
		lineTo(x + w, y);
		lineTo(x + w, y + h);
		lineTo(x, y + h);
		closePath();
	}

	static Path fromRectangle(double x, double y, double w, double h) {
		Path path = new Path;
		path.rectangle(x, y, w, h);
		return path;
	}

	void ellipse(double x, double y, double w, double h) {
		// Magic number taken from https://stackoverflow.com/questions/1734745/how-to-create-circle-with-b%C3%A9zier-curves
		double magic = 4.0 * (sqrt(2.0) - 1.0) / 3.0 / 2;
		double cx = x + w / 2;
		double cy = y + h / 2;
		moveTo(x + w, cy);
		bezierCurveTo(
			x + w, cy - magic * h,
			cx + magic * w, y,
			cx, y
		);
		bezierCurveTo(
			cx - magic * w, y,
			x, cy - magic * h,
			x, cy
		);
		bezierCurveTo(
			x, cy + magic * h,
			cx - magic * w, y + h,
			cx, y + h,
		);
		bezierCurveTo(
			cx + magic * w, y + h,
			x + w, cy + magic * h,
			x + w, cy,
		);
		closePath();
	}

	static Path fromEllipse(double x, double y, double w, double h) {
		Path path = new Path;
		path.ellipse(x, y, w, h);
		return path;
	}

	void line(double x1, double y1, double x2, double y2) {
		moveTo(x1, y1);
		lineTo(x2, y2);
	}

	static Path fromLine(double x1, double y1, double x2, double y2) {
		Path path = new Path;
		path.line(x1, y1, x2, y2);
		return path;
	}

	Path translate(double x, double y) const {
		Path result = new Path;
		result.atX = atX + x;
		result.atY = atY + y;
		result.editingSubpath = editingSubpath;
		foreach (subpath; subpaths) {
			result.moveTo(subpath.startX + x, subpath.startY + y);
			foreach (line; subpath.lines) {
				result.bezierCurveTo(line[0] + x, line[1] + y,
					line[2] + x, line[3] + y, line[4] + x, line[5] + y);
			}
			if (subpath.closed) {
				result.closePath();
			}
		}
		return result;
	}

	Path scale(double xy) const {
		return scale(xy, xy);
	}

	Path scale(double x, double y) const {
		Path result = new Path;
		result.atX = atX * x;
		result.atY = atY * y;
		result.editingSubpath = editingSubpath;
		foreach (subpath; subpaths) {
			result.moveTo(subpath.startX * x, subpath.startY * y);
			foreach (line; subpath.lines) {
				result.bezierCurveTo(line[0] * x, line[1] * y,
					line[2] * x, line[3] * y, line[4] * x, line[5] * y);
			}
			if (subpath.closed) {
				result.closePath();
			}
		}
		return result;
	}

	void add(const(Path) other) { // TODO: turn into actual union operation
		foreach (subpath; other.subpaths) {
			moveTo(subpath.startX, subpath.startY);
			foreach (line; subpath.lines) {
				bezierCurveTo(line[0], line[1], line[2], line[3], line[4], line[5]);
			}
			if (subpath.closed) {
				closePath();
			}
		}
	}

	Path clone() const {
		Path result = new Path;
		result.add(this);
		return result;
	}

}

abstract class Source {
	protected abstract Object set(Context ctx);
	protected abstract void cleanup(Object obj);
}

final class ColorSource : Source {
	Color color;

	this(Color color = Color(0, 0, 0, 255)) {
		this.color = color;
	}

	override Object set(Context ctx) {
		ctx.setSourceRgba(color.r / 255.0, color.g / 255.0, color.b / 255.0, color.a / 255.0);
		return null;
	}

	override void cleanup(Object obj) {}
}

enum InterpolationMode {
	Nearest,
	Bilinear,
}

final class ImageSource : Source {
	private class CleanupData {
		ImageSurface surface;
		Pattern pattern;
	}

	const(Surface) surface;
	double offsetX;
	double offsetY;
	double scaleX;
	double scaleY;
	InterpolationMode mode;

	this(const(Surface) surface,
			double offsetX = 0, double offsetY = 0,
			double scaleX = 1, double scaleY = 1,
			InterpolationMode mode = InterpolationMode.Bilinear,
		) {
		this.surface = surface;
		this.offsetX = offsetX;
		this.offsetY = offsetY;
		this.scaleX = scaleX;
		this.scaleY = scaleY;
		this.mode = mode;
	}

	override Object set(Context ctx) {
		ImageSurface target = ImageSurface.createForData(cast(ubyte*) surface.data.ptr,
			cairo_format_t.ARGB32, surface.width, surface.height, cast(int) surface.pitch * 4);
		Pattern pattern = Pattern.createForSurface(target);
		cairo_matrix_t matrixData;
		Matrix matrix = new Matrix(&matrixData);
		matrix.initIdentity();
		matrix.translate(-offsetX / scaleX, -offsetY / scaleX);
		matrix.scale(1.0 / scaleX, 1.0 / scaleY);
		pattern.setMatrix(matrix);
		pattern.setExtend(cairo_extend_t.REPEAT);
		if (mode == InterpolationMode.Nearest) {
			pattern.setFilter(cairo_filter_t.NEAREST);
		}
		else {
			pattern.setFilter(cairo_filter_t.BILINEAR);
		}
		ctx.setSource(pattern);
		CleanupData data = new CleanupData;
		data.surface = target;
		data.pattern = pattern;
		return data;
	}

	override void cleanup(Object obj) {
		CleanupData data = cast(CleanupData) obj;
		data.pattern.destroy();
		data.surface.destroy();
	}
}

enum LineJoin {
	Miter,
	Round,
	Bevel,
}

enum LineCap {
	Butt,
	Round,
	Square,
}

struct StrokeStyle {
	double thickness = 1;
	double[] dashes = [];
	double dashOffset = 0;
	LineJoin join = LineJoin.Round;
	LineCap cap = LineCap.Round;
}

struct Canvas {
	Surface surface;
	bool antialias = true;
	private Path _clip;

	private this(inout(Surface) surface) inout {
		this.surface = surface;
	}

	this(uint width, uint height) {
		surface = Surface(new Color[width * height], width, height);
		surface.data[] = Color(0, 0, 0, 0);
	}

	static Canvas fromSurface(Surface surface) {
		return Canvas(surface);
	}

	const(Path) clip() {
		return _clip;
	}

	void clip(const(Path) path) {
		if (path is null) {
			_clip = null;
		}
		else {
			_clip = path.clone();
		}
	}

	void fill(Source src, Path path) {
		ImageSurface target = ImageSurface.createForData(cast(ubyte*) surface.data.ptr,
			cairo_format_t.ARGB32, surface.width, surface.height, cast(int) surface.pitch * 4);
		Context ctx = Context.create(target);

		if (clip && !clip.empty) {
			foreach (subpath; clip.subpaths) {
				ctx.moveTo(subpath.startX, subpath.startY);
				foreach (line; subpath.lines) {
					ctx.curveTo(line[0], line[1], line[2], line[3], line[4], line[5]);
				}
				if (subpath.closed) {
					ctx.closePath();
				}
			}
			ctx.clip();
			ctx.newPath();
		}

		foreach (subpath; path.subpaths) {
			ctx.moveTo(subpath.startX, subpath.startY);
			foreach (line; subpath.lines) {
				ctx.curveTo(line[0], line[1], line[2], line[3], line[4], line[5]);
			}
			if (subpath.closed) {
				ctx.closePath();
			}
		}
		ctx.setFillRule(cairo_fill_rule_t.EVEN_ODD);
		if (antialias) {
			ctx.setAntialias(cairo_antialias_t.GOOD);
		}
		else {
			ctx.setAntialias(cairo_antialias_t.NONE);
		}
		Object data = src.set(ctx);
		ctx.fill();

		target.flush();
		target.finish();
		src.cleanup(data);
		ctx.destroy();
		target.destroy();
	}

	void stroke(Source src, double thickness, const(Path) path) {
		stroke(src, StrokeStyle(thickness), path);
	}

	void stroke(Source src, StrokeStyle style, const(Path) path) {
		// TODO: replace with fill(src, path.stroke(style))

		ImageSurface target = ImageSurface.createForData(cast(ubyte*) surface.data.ptr,
			cairo_format_t.ARGB32, surface.width, surface.height, cast(int) surface.pitch * 4);
		Context ctx = Context.create(target);

		if (clip && !clip.empty) {
			foreach (subpath; clip.subpaths) {
				ctx.moveTo(subpath.startX, subpath.startY);
				foreach (line; subpath.lines) {
					ctx.curveTo(line[0], line[1], line[2], line[3], line[4], line[5]);
				}
				if (subpath.closed) {
					ctx.closePath();
				}
			}
			ctx.clip();
			ctx.newPath();
		}

		foreach (subpath; path.subpaths) {
			ctx.moveTo(subpath.startX, subpath.startY);
			foreach (line; subpath.lines) {
				ctx.curveTo(line[0], line[1], line[2], line[3], line[4], line[5]);
			}
			if (subpath.closed) {
				ctx.closePath();
			}
		}
		if (antialias) {
			ctx.setAntialias(cairo_antialias_t.GOOD);
		}
		else {
			ctx.setAntialias(cairo_antialias_t.NONE);
		}
		Object data = src.set(ctx);
		ctx.setDash(style.dashes, style.dashOffset);
		final switch (style.join) {
		case LineJoin.Miter:
			ctx.setLineJoin(cairo_line_join_t.MITER);
			break;
		case LineJoin.Round:
			ctx.setLineJoin(cairo_line_join_t.ROUND);
			break;
		case LineJoin.Bevel:
			ctx.setLineJoin(cairo_line_join_t.BEVEL);
			break;
		}
		final switch (style.cap) {
		case LineCap.Butt:
			ctx.setLineCap(cairo_line_cap_t.BUTT);
			break;
		case LineCap.Round:
			ctx.setLineCap(cairo_line_cap_t.ROUND);
			break;
		case LineCap.Square:
			ctx.setLineCap(cairo_line_cap_t.SQUARE);
			break;
		}
		ctx.setLineWidth(style.thickness);
		ctx.stroke();

		target.flush();
		target.finish();
		src.cleanup(data);
		ctx.destroy();
		target.destroy();
	}

	ImageSurface cairo() {
		return ImageSurface.createForData(cast(ubyte*) surface.data.ptr,
			cairo_format_t.ARGB32, surface.width, surface.height, cast(int) surface.pitch * 4);
	}
}
