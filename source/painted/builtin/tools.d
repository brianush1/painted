module painted.builtin.tools;
import painted.utils;
import painted.api;
import graphics.canvas;
import std.math;
import std.range;
import std.algorithm;
import std.conv;

void initBuiltinTools() {
	registerTool("select-rect", new class Tool {

		this() {
			displayName = "Rectangle Select";
			iconData = cast(ubyte[]) import("images/select-rect.png");
			target = Target.PixelCorner;
			selectionBehavior = SelectionBehavior.Modifier;

			Project.Edit edit;
			int startX, startY;
			bool down = false;
			onPress.connect((Project project, MouseButton btn, int x, int y, int, int) {
				edit = project.startEdit("Rectangle Select");
				startX = x;
				startY = y;
				down = true;
				project.edit(edit, (Project.EditData data) {
					data.selection.clear();
				});
			});
			onMove.connect((Project project, int x, int y, int, int, Modifiers mods) {
				if (down) {
					project.edit(edit, (Project.EditData data) {
						data.selection.clear();
						int width = x - startX;
						int height = y - startY;
						if (width != 0 && height != 0) {
							if (mods & Modifiers.Shift) {
								int x = min(width.abs, height.abs);
								width = width / width.abs * x;
								height = height / height.abs * x;
							}
							data.selection.rectangle(startX, startY, width, height);
						}
						if (mods & Modifiers.Ctrl) {
							data.selection.add(data.originalSelection);
						}
					});
				}
			});
			onRelease.connect((Project project, MouseButton btn, int x, int y, int, int) {
				project.commit(edit);
				down = false;
			});
		}

	});

	registerTool("select-ellipse", new class Tool {

		this() {
			displayName = "Ellipse Select";
			iconData = cast(ubyte[]) import("images/select-rect.png");
			target = Target.PixelCorner;
			selectionBehavior = SelectionBehavior.Modifier;

			Project.Edit edit;
			int startX, startY;
			bool down = false;
			onPress.connect((Project project, MouseButton btn, int x, int y, int, int) {
				edit = project.startEdit("Ellipse Select");
				startX = x;
				startY = y;
				down = true;
				project.edit(edit, (Project.EditData data) {
					data.selection.clear();
				});
			});
			onMove.connect((Project project, int x, int y, int, int, Modifiers mods) {
				if (down) {
					project.edit(edit, (Project.EditData data) {
						data.selection.clear();
						int width = x - startX;
						int height = y - startY;
						if (width != 0 && height != 0) {
							if (mods & Modifiers.Shift) {
								int x = min(width.abs, height.abs);
								width = width / width.abs * x;
								height = height / height.abs * x;
							}
							data.selection.ellipse(startX, startY, width, height);
						}
						if (mods & Modifiers.Ctrl) {
							data.selection.add(data.originalSelection);
						}
					});
				}
			});
			onRelease.connect((Project project, MouseButton btn, int x, int y, int, int) {
				project.commit(edit);
				down = false;
			});
		}

	});

	registerTool("pan", new class Tool {

		this() {
			displayName = "Pan";
			iconData = cast(ubyte[]) import("images/pan.png");
			target = Target.None;

			int startX, startY;
			bool down = false;
			onPress.connect((Project project, MouseButton btn, int x, int y, int rawX, int rawY) {
				startX = rawX;
				startY = rawY;
				down = true;
			});
			onMove.connect((Project project, int x, int y, int rawX, int rawY, Modifiers) {
				if (down) {
					project.viewX += rawX - startX;
					project.viewY += rawY - startY;
					startX = rawX;
					startY = rawY;
				}
			});
			onRelease.connect((Project project, MouseButton btn, int x, int y, int rawX, int rawY) {
				down = false;
			});
		}

	});

	registerTool("pencil", new class Tool {

		this() {
			displayName = "Pixel Pencil";
			iconData = cast(ubyte[]) import("images/pencil.png");
			target = Target.PixelCenter;

			Project.Edit edit;

			Path path;
			auto move = (Project project, int x, int y, int, int, Modifiers mods) {
				project.edit(edit, (Project.EditData data) {
					data.surface.copyFrom(data.originalSurface);
					Canvas canvas = Canvas.fromSurface(data.surface);
					canvas.clip = data.selection;
					path.lineTo(x, y);
					canvas.antialias = false;
					canvas.stroke(new ColorSource(preferredColor), 1, path.translate(0.5, 0.5));
				});
			};
			onPress.connect((Project project, MouseButton btn, int x, int y, int, int) {
				edit = project.startEdit("Pixel Pencil");
				path = new Path;
				path.moveTo(x, y);
				move(project, x, y, 0, 0, Modifiers.None);
			});
			onMove.connect(move);
			onRelease.connect((Project project, MouseButton btn, int x, int y, int, int) {
				project.commit(edit);
				edit = null;
			});
		}

	});

	registerTool("paintbrush", new class Tool {

		this() {
			displayName = "Paintbrush";
			iconData = cast(ubyte[]) import("images/paintbrush.png");
			target = Target.PixelCenter;

			Project.Edit edit;

			int[2][] points;
			bool other = true;
			auto move = (Project project, int x, int y, int, int, Modifiers mods) {
				points ~= [x, y];
				project.edit(edit, (Project.EditData data) {
					data.surface.copyFrom(data.originalSurface);
					Canvas canvas = Canvas.fromSurface(data.surface);
					canvas.clip = data.selection;
					Path path = new Path;
					alias T = double[2];
					double[2][] cAfter = new T[points.length];
					double[2][] cBefore = new T[points.length];
					foreach (i; 0 .. points.length) {
						double[2] point = points[i].to!(double[2]);
						cAfter[i] = point;
						cBefore[i] = point;
					}
					foreach (i; 0 .. points.length) {
						if (i + 2 >= points.length)
							break;
						double[2] a = points[i].to!(double[2]);
						double[2] b = points[i + 1].to!(double[2]);
						double[2] c = points[i + 2].to!(double[2]);
						double[2] mid = [(a[0] + c[0]) / 2, (a[1] + c[1]) / 2];
						double[2] midToA = [a[0] - mid[0], a[1] - mid[1]];
						double[2] midToC = [c[0] - mid[0], c[1] - mid[1]];
						cBefore[i + 1] = [
							b[0] + midToA[0] / 4,
							b[1] + midToA[1] / 4,
						];
						cAfter[i + 1] = [
							b[0] + midToC[0] / 4,
							b[1] + midToC[1] / 4,
						];
					}
					foreach (i; 0 .. points.length) {
						double[2] point = points[i].to!(double[2]);
						if (i == 0) {
							path.moveTo(point[0], point[1]);
						}
						else {
							double[2] c1 = cAfter[i - 1];
							double[2] c2 = cBefore[i];
							path.bezierCurveTo(c1[0], c1[1], c2[0], c2[1], point[0], point[1]);
						}
					}
					canvas.stroke(new ColorSource(preferredColor), 8, path.translate(0.5, 0.5));
					Path realPath = new Path;
					foreach (i; 0 .. points.length) {
						double[2] point = points[i].to!(double[2]);
						if (i == 0) {
							realPath.moveTo(point[0], point[1]);
						}
						else {
							realPath.lineTo(point[0], point[1]);
						}
					}
					// canvas.stroke(new ColorSource(Color(255, 0, 0, 255)), 2, realPath.translate(0.5, 0.5));
				});
			};
			onPress.connect((Project project, MouseButton btn, int x, int y, int, int) {
				edit = project.startEdit("Paintbrush");
				points = [[x, y]];
				move(project, x, y, 0, 0, Modifiers.None);
			});
			onMove.connect(move);
			onRelease.connect((Project project, MouseButton btn, int x, int y, int, int) {
				project.commit(edit);
				edit = null;
			});
		}

		override Path getPixelHighlightPath() {
			return Path.fromEllipse(-4, -4, 8, 8);
		}

	});

	refreshPlugins();
}
