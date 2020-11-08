module painted.ui;
import painted.utils;
import painted.api;
import painted.api : Layer;
import graphics.canvas;
import gtk.MainWindow;
import gtk.Main;
import gtk.Widget;
import gtk.Button;
import gtk.DrawingArea;
import gtk.Stack;
import gtk.AccelGroup;
import gtk.Label;
import gtk.Box;
import gtk.Menu;
import gtk.MenuBar;
import gtk.MenuItem;
import gtk.SeparatorMenuItem;
import gtk.MenuButton;
import gtk.MenuShell;
import gtk.Separator;
import gtk.ScrolledWindow;
import gtk.VBox;
import gtk.HBox;
import gtk.Box;
import gtk.FlowBox;
import gtk.CssProvider;
import gtk.StyleContext;
import gtk.Image;
import gtk.Dialog;
import gtk.TreeView;
import gtk.TreeViewColumn;
import gtk.TreeModel;
import gtk.TreeIter;
import gtk.TreePath;
import gtk.ListStore;
import gtk.CellRendererPixbuf;
import gtk.CellRendererText;
import gtk.Notebook;
import gtk.CheckMenuItem;
import gobject.Value;
import cairo.Context;
import cairo.Pattern;
import cairo.ImageSurface;
import gdk.Keysyms;
import gdk.Pixbuf;
import gdk.Cairo;
import gdk.Event;
import gdl.Dock;
import gdl.DockBar;
import gdl.DockItem;
import gdl.DockObject;
import gdl.DockLayout;
import gdl.DockMaster;
import std.math;
import std.typecons;
import std.range;
import std.algorithm;
import imageformats;

package:

enum MARCHING_ANTS_SPEED = 32;

void applyCss(string stylesheet)(StyleContext styleContext) {
	auto provider = new CssProvider();
	provider.loadFromData(import("css/" ~ stylesheet));
	styleContext.addProvider(provider, GTK_STYLE_PROVIDER_PRIORITY_APPLICATION);
}

final class CanvasWidget : DrawingArea {

	private int convertX(Widget widget, double x) {
		return cast(int) roundingFunction()((x - (widget.getAllocatedWidth()
				- project.width * project.zoomScale) / 2 - project.viewX)
			/ project.zoomScale);
	}

	private int convertY(Widget widget, double y) {
		return cast(int) roundingFunction()((y - (widget.getAllocatedHeight()
				- project.height * project.zoomScale) / 2 - project.viewY)
			/ project.zoomScale);
	}

	private double delegate(double) roundingFunction() {
		if (selectedTool.target == Target.PixelCorner) {
			return (double x) => round(x);
		}
		else {
			return (double x) => floor(x);
		}
	}

	private Modifiers getModifiers(ModifierType state) {
		Modifiers mods = Modifiers.None;
		if (state & ModifierType.CONTROL_MASK) mods |= Modifiers.Ctrl;
		if (state & ModifierType.SHIFT_MASK) mods |= Modifiers.Shift;
		// TODO: this
		// if (state & ModifierType.ALT_MASK) mods |= Modifiers.Alt;
		return mods;
	}

	this(Project project) {
		super();

		setSizeRequest(256, 256);

		Tool rememberTool;
		addOnButtonPress((GdkEventButton* ev, Widget widget) {
			int x = convertX(widget, ev.x);
			int y = convertY(widget, ev.y);
			lastX = ev.x;
			lastY = ev.y;
			if (ev.button == 1) {
				usingSecondary = false;
				selectedTool.onPress.emit(project, MouseButton.Left, x, y, cast(int) ev.x, cast(int) ev.y);
			}
			else if (ev.button == 3) {
				usingSecondary = true;
				selectedTool.onPress.emit(project, MouseButton.Right, x, y, cast(int) ev.x, cast(int) ev.y);
			}
			else if (ev.button == 2) {
				rememberTool = selectedTool;
				tool("pan").select();
				tool("pan").onPress.emit(project, MouseButton.Left, x, y, cast(int) ev.x, cast(int) ev.y);
			}
			return true;
		});

		addOnButtonRelease((GdkEventButton* ev, Widget widget) {
			int x = convertX(widget, ev.x);
			int y = convertY(widget, ev.y);
			lastX = ev.x;
			lastY = ev.y;
			if (ev.button == 1) {
				selectedTool.onRelease.emit(project, MouseButton.Left, x, y, cast(int) ev.x, cast(int) ev.y);
			}
			else if (ev.button == 3) {
				selectedTool.onRelease.emit(project, MouseButton.Right, x, y, cast(int) ev.x, cast(int) ev.y);
			}
			else if (ev.button == 2) {
				if (tool("pan").selected && rememberTool !is null) {
					tool("pan").onRelease.emit(project, MouseButton.Left, x, y, cast(int) ev.x, cast(int) ev.y);
					rememberTool.select();
				}
			}
			usingSecondary = false;
			project.save();
			return true;
		});

		addOnScroll((GdkEventScroll* ev, Widget widget) {
			import std.math : pow;

			int x = convertX(widget, ev.x);
			int y = convertY(widget, ev.y);
			lastX = ev.x;
			lastY = ev.y;
			double dx = ev.deltaX;
			double dy = ev.deltaY;
			if (ev.direction == GdkScrollDirection.DOWN) {
				dx = 0;
				dy = -1;
			}
			else if (ev.direction == GdkScrollDirection.UP) {
				dx = 0;
				dy = 1;
			}
			double factor = pow(sqrt(2.0), dy);
			double zoomScaleOld = project.zoomScale;
			project.zoomScale *= factor;
			double width = widget.getAllocatedWidth();
			double height = widget.getAllocatedHeight();
			project.viewX = cast(int) -((ev.x - (width - project.width * zoomScaleOld) / 2 - project.viewX)
				/ zoomScaleOld * project.zoomScale
				- (ev.x - (width - project.width * project.zoomScale) / 2));
			project.viewY = cast(int) -((ev.y - (height - project.height * zoomScaleOld) / 2 - project.viewY)
				/ zoomScaleOld * project.zoomScale
				- (ev.y - (height - project.height * project.zoomScale) / 2));
			return true;
		});

		addOnMotionNotify((GdkEventMotion* ev, Widget widget) {
			int x = convertX(widget, ev.x);
			int y = convertY(widget, ev.y);
			lastX = ev.x;
			lastY = ev.y;
			highlightX = x;
			highlightY = y;
			selectedTool.onMove.emit(project, x, y, cast(int) ev.x, cast(int) ev.y,
				getModifiers(ev.state));
			return true;
		});

		addOnDraw((Scoped!Context ctx, Widget widget) {
			int width = widget.getAllocatedWidth();
			int height = widget.getAllocatedHeight();

			Canvas canvas = Canvas(width, height);

			int translateX = cast(int)((width - project.width * project.zoomScale) / 2 + project.viewX),
				translateY = cast(int)((height - project.height * project.zoomScale) / 2 + project.viewY);

			canvas.fill(new ColorSource(Color(204, 204, 204, 255)),
				Path.fromRectangle(0, 0, width, height));

			drawLayers(canvas, translateX, translateY);

			// drawGrid(canvas, translateX, translateY);

			if (selectedTool.target == Target.PixelCenter) {
				highlightPixelCenter(canvas, translateX, translateY, highlightX, highlightY);
			}
			else if (selectedTool.target == Target.PixelCorner) {
				highlightPixelCorner(canvas, translateX, translateY, highlightX, highlightY);
			}

			ImageSurface surface = cast(ImageSurface) canvas.cairo();
			Pattern pattern = Pattern.createForSurface(surface);
			ctx.setSource(pattern);
			ctx.rectangle(0, 0, width, height);
			ctx.fill();
			surface.destroy();
			pattern.destroy();

			queueDraw();

			return true;
		});
	}

	int highlightX, highlightY;
	double lastX, lastY;

	private void highlightPixelCenter(Canvas canvas, int translateX, int translateY, int x, int y) {
		int offsetX = translateX + cast(int) round(project.zoomScale * x);
		int offsetY = translateY + cast(int) round(project.zoomScale * y);
		Path path = selectedTool.getPixelHighlightPath();
		canvas.stroke(new ColorSource(Color(0, 0, 0, 255)), 2,
			path.translate(0.5, 0.5).scale(project.zoomScale).translate(offsetX, offsetY));
		canvas.stroke(new ColorSource(Color(255, 255, 255, 255)), 1,
			path.translate(0.5, 0.5).scale(project.zoomScale).translate(offsetX, offsetY));
	}

	private void highlightPixelCorner(Canvas canvas, int translateX, int translateY, int x, int y) {
		int pixelSize = cast(int) round(project.zoomScale);
		int offsetX = translateX + cast(int) round(project.zoomScale * x);
		int offsetY = translateY + cast(int) round(project.zoomScale * y);
		Path path = new Path;
		path.line(offsetX - 4, offsetY + 0.5, offsetX + 5, offsetY + 0.5);
		path.line(offsetX + 0.5, offsetY - 4, offsetX + 0.5, offsetY + 5);
		canvas.stroke(new ColorSource(Color(255, 255, 255, 255)), 3, path);
		canvas.stroke(new ColorSource(Color(0, 0, 0, 255)), 1, path);
	}

	Canvas gridCanvas;
	Tuple!(uint, uint, double) gridState;

	private void drawGrid(Canvas canvas, int translateX, int translateY) {
		// TODO: improve performance

		import std.algorithm : min, max;

		if (project.zoomScale >= 3 - 1e-9) {
			int renderedWidth = min(cast(int) ceil(canvas.surface.width / project.zoomScale + 1), project.width);
			int renderedHeight = min(cast(int) ceil(canvas.surface.height / project.zoomScale + 1), project.height);
			int canvasSizeX = cast(int)(project.width * project.zoomScale);
			int canvasSizeY = cast(int)(project.height * project.zoomScale);
			auto state = tuple(renderedWidth, renderedHeight, project.zoomScale);
			if (gridState != state) {
				gridState = state;
				gridCanvas = Canvas(cast(uint)(renderedWidth * project.zoomScale),
					cast(uint)(renderedHeight * project.zoomScale));
				Path path = new Path;
				foreach (i; 1 .. renderedWidth) {
					path.moveTo(cast(int)(i * project.zoomScale) + 0.5, 0);
					path.lineTo(cast(int)(i * project.zoomScale) + 0.5, gridCanvas.surface.height);
				}
				foreach (j; 1 .. renderedHeight) {
					path.moveTo(0, cast(int)(j * project.zoomScale) + 0.5);
					path.lineTo(gridCanvas.surface.width, cast(int)(j * project.zoomScale) + 0.5);
				}
				gridCanvas.stroke(new ColorSource(Color(128, 128, 128, 255)),
					StrokeStyle(1, [1, 1], 0, LineJoin.Round, LineCap.Butt), path);
			}
			Path gridPath = new Path;
			gridPath.rectangle(translateX, translateY, canvasSizeX, canvasSizeY);
			canvas.fill(new ImageSource(gridCanvas.surface,
				cast(int) round(translateX % project.zoomScale),
				cast(int) round(translateY % project.zoomScale),
			), gridPath);
		}
	}

	private void drawLayers(Canvas canvas, int translateX, int translateY) {
		Path path = new Path;
		path.rectangle(translateX, translateY,
			project.width * project.zoomScale, project.height * project.zoomScale);
		Layer[] layers = project.getLayers(true);
		foreach (layer; layers) {
			auto src = new ImageSource(
				const(Surface)(layer.bitmap, project.width, project.height),
				translateX, translateY, project.zoomScale, project.zoomScale,
			);
			if (project.zoomScale >= 2 - 1e-9) {
				src.mode = InterpolationMode.Nearest;
			}
			else {
				src.mode = InterpolationMode.Bilinear;
			}
			canvas.fill(src, path);
		}
		const(Path) sel = project.getSelection(true);
		canvas.antialias = false;
		if (selectedTool.selectionBehavior == SelectionBehavior.Modifier) {
			canvas.fill(new ColorSource(Color(0, 128, 255, 60)),
				sel.scale(project.zoomScale).translate(translateX, translateY));
		}
		canvas.stroke(new ColorSource(Color(0, 0, 0, 255)), StrokeStyle(
			1, [4, 4], (getUnixTime() * MARCHING_ANTS_SPEED) % 8, LineJoin.Bevel, LineCap.Butt,
		), sel.scale(project.zoomScale).translate(translateX, translateY));
		canvas.stroke(new ColorSource(Color(255, 255, 255, 255)), StrokeStyle(
			1, [4, 4], (getUnixTime() * MARCHING_ANTS_SPEED + 4) % 8, LineJoin.Bevel, LineCap.Butt,
		), sel.scale(project.zoomScale).translate(translateX, translateY));
	}

}

class Toolbox : VBox {

	this() {
		super(false, 0);

		setSizeRequest(36, 128);

		addRefreshHandler(&refresh);
	}

	void refresh() {
		removeAll();

		auto inner = new FlowBox;

		inner.setSelectionMode(GtkSelectionMode.NONE);
		inner.setRowSpacing(0);
		inner.setColumnSpacing(0);

		foreach (_tool; tools) {
			(){
				Tool tool = _tool;
				Button button;
				if (_tool.iconData.length != 0) {
					import core.memory : GC;

					IFImage img = read_image_from_mem(_tool.iconData, ColFmt.RGBA);
					GC.addRoot(cast(void*) img.pixels.ptr);
					Pixbuf pixbuf = new Pixbuf(cast(char[]) img.pixels, GdkColorspace.RGB, true, 8,
						img.w, img.h, img.w * 4, cast(GdkPixbufDestroyNotify)((char*, void* data) {
							GC.removeRoot(data);
						}), cast(void*) img.pixels.ptr);
					button = new Button();
					button.add(new Image(pixbuf));
					button.setTooltipText(tool.displayName);
				}
				else {
					button = new Button(tool.displayName);
				}
				auto ctx = button.getStyleContext();
				applyCss!"toolbox.css"(ctx);
				if (tool.selected)
					ctx.addClass("selected");
				tool.onSelect.connect({
					ctx.addClass("selected");
				});
				tool.onDeselect.connect({
					ctx.removeClass("selected");
				});
				button.addOnClicked((Button) {
					tool.select();
				});
				button.setSizeRequest(24, 24);
				inner.insert(button, -1);
			}();
		}

		packStart(inner, false, false, 0);

		showAll();
	}

}

class HistoryList : TreeView {

	Project project;

	this(Project project) {
		import core.memory : GC;

		super();

		this.project = project;

		setHeadersVisible(false);
		setGridLines(GtkTreeViewGridLines.NONE);
		setEnableTreeLines(false);
		setEnableSearch(false);
		getSelection().setMode(GtkSelectionMode.SINGLE);

		TreeViewColumn textColumn = new TreeViewColumn;
		CellRendererText textCell = new CellRendererText;
		textColumn.packStart(textCell, true);
		GC.addRoot(cast(void*) this);
		textColumn.setCellDataFunc(textCell,
			cast(GtkTreeCellDataFunc)(GtkTreeViewColumn* treeColumn,
					GtkCellRenderer* cell, GtkTreeModel* treeModel,
					GtkTreeIter* iterptr, void* data) {
				HistoryList self = cast(HistoryList) data;
				CellRendererText textCell2
					= new CellRendererText(cast(GtkCellRendererText*) cell);
				TreeIter iter = new TreeIter(iterptr);
				iter.setModel(treeModel);
				Value value = new Value;
				iter.getValue(0, value);
				int index = iter.getTreePath().getIndices()[0];
				bool historical = index < self.project.history.length;
				if (historical) {
					textCell2.setProperty("style", PangoStyle.NORMAL);
					textCell2.setProperty("foreground", "black");
				}
				else {
					textCell2.setProperty("style", PangoStyle.OBLIQUE);
					textCell2.setProperty("foreground", "gray");
				}
				textCell2.setProperty("text", value.getString());
			}, cast(void*) this, cast(GDestroyNotify)(void* data) {
				GC.removeRoot(data);
			},
		);

		appendColumn(textColumn);

		ListStore historyModel = new ListStore([GType.STRING]);

		TreeIter[] iters;

		foreach (str; project.history.merge(project.future)) {
			TreeIter iter;
			historyModel.insert(iter, -1);
			historyModel.set(iter, [0], [str]);
			iters.assumeSafeAppend ~= iter;
		}

		setModel(historyModel);
		setSearchColumn(-1);

		getSelection().selectIter(iters[project.history.length - 1]);

		bool handlingHistoryEvent = false;

		project.historyAdded.connect((string name, int historyLength) {
			handlingHistoryEvent = true;
			foreach (iter; iters[historyLength - 1 .. $]) {
				historyModel.remove(iter);
			}
			iters = iters[0 .. historyLength - 1];
			TreeIter iter;
			historyModel.insert(iter, -1);
			historyModel.set(iter, [0], [name]);
			iters.assumeSafeAppend ~= iter;
			getSelection().selectIter(iter);
			scrollToCell(new TreePath([historyLength - 1]), null, false, 0, 0);
			handlingHistoryEvent = false;
		});

		project.historyUndoRedo.connect((int historyLength) {
			handlingHistoryEvent = true;
			getSelection().selectIter(iters[historyLength - 1]);
			scrollToCell(new TreePath([historyLength - 1]), null, false, 0, 0);
			handlingHistoryEvent = false;
		});

		auto handler = delegate int(TreePath path) {
			if (handlingHistoryEvent)
				return 1;
			int[] indices = path.getIndices();
			if (indices.length != 1) {
				return 0;
			}
			else {
				int index = indices[0];
				int dx = index - cast(int) project.history.length + 1;
				if (dx < 0) {
					foreach (i; 0 .. -dx) {
						project.undo();
					}
				}
				else {
					foreach (i; 0 .. dx) {
						project.redo();
					}
				}
				return 1;
			}
		};

		auto handlerPtr = cast(int delegate(TreePath)*) GC.malloc((int delegate(TreePath)).sizeof);
		*handlerPtr = handler;

		GC.addRoot(cast(void*) handlerPtr);
		getSelection().setSelectFunction(
			cast(GtkTreeSelectionFunc)(GtkTreeSelection* selection,
					GtkTreeModel* model, GtkTreePath* path_,
					int pathCurrentlySelected, void* data) {
				int delegate(TreePath) mhandler = *cast(int delegate(TreePath)*) data;
				TreePath path = new TreePath(path_);
				return mhandler(path);
			}, cast(void*) handlerPtr, cast(GDestroyNotify)(void* data) {
				GC.removeRoot(data);
			},
		);
	}

}

class History : ScrolledWindow {

	this(Project project) {
		super();
		setSizeRequest(128, 128);

		add(new HistoryList(project));

		showAll();
	}

}

class Colors : VBox {

	this() {
		super(false, 0);

		setSizeRequest(128, 128);
	}

}

class Layers : VBox {

	this() {
		super(false, 0);

		setSizeRequest(128, 128);

		add(new Label("test"));
	}

}

class Effects : MenuItem {

	this() {
		super("Effects");
		auto effectsMenu = new Menu;
		setSubmenu(effectsMenu);

		addRefreshHandler({
			effectsMenu.removeAll();

			foreach (effect; effects) {
				MenuItem item = new MenuItem((MenuItem) {
					auto edit = project.startEdit(effect.displayName);
					project.edit(edit, (Project.EditData data) {
						bool isCancelRequested = false;
						effect.apply(data.originalSurface, data.surface,
							Rect(0, 0, data.surface.width, data.surface.height), &isCancelRequested);
					});
					project.commit(edit);
				}, effect.displayName, "activate", false);

				effectsMenu.append(item);
			}

			showAll();
		});
	}

}

MenuItem createMenuItem(AccelGroup accelGroup, string name,
	Keysyms key, ModifierType mods, void delegate() handler) {
	auto item = new MenuItem(name, true);
	item.addOnActivate((MenuItem) { handler(); });
	item.addAccelerator("activate", accelGroup, key, mods, AccelFlags.VISIBLE);
	return item;
}

class DockMenuItem : CheckMenuItem {

	private DockItem item;

	this(string name, DockItem item) {
		super(name);
		this.item = item;
		addOnToggled((CheckMenuItem) {
			if (getActive()) {
				item.showItem();
			}
			else {
				item.hideItem();
			}
		});
	}

	void update() {
		setActive(item.getVisible());
	}

}

final class PaintedWindow : MainWindow {

	AccelGroup accelGroup;
	Dock dock;
	DockLayout layout;
	string currentLayout = "Default";

	this() {
		super("Painted");

		VBox vbox = new VBox(false, 0);
		add(vbox);

		accelGroup = new AccelGroup();
		addAccelGroup(accelGroup);

		projects ~= Project.create("test-img-2", 1920, 1080);
		projects ~= Project.create("test-img-3", 640, 480);

		CanvasWidget canvas = new CanvasWidget(projects[0]);
		CanvasWidget canvas2 = new CanvasWidget(projects[1]);

		Notebook canvasTabs = new Notebook;
		canvasTabs.insertPage(canvas, new Label("Project 1"), -1);
		canvasTabs.insertPage(canvas2, new Label("Project 2"), -1);
		canvasTabs.addOnSwitchPage((Widget, uint index, Notebook) {
			selectedProject = index;
		});

		dock = new Dock;
		layout = new DockLayout(dock);
		auto menubar = new MenuBar;

		auto file = new MenuItem("File");
		auto fileMenu = new Menu;
		file.setSubmenu(fileMenu);
		menubar.append(file);

		fileMenu.append(accelGroup.createMenuItem("New", Keysyms.GDK_n, ModifierType.CONTROL_MASK, {
			newProject();
		}));

		fileMenu.append(accelGroup.createMenuItem("Open", Keysyms.GDK_o, ModifierType.CONTROL_MASK, {
			
		}));

		fileMenu.append(accelGroup.createMenuItem("Close", Keysyms.GDK_w, ModifierType.CONTROL_MASK, {
			
		}));

		fileMenu.append(new SeparatorMenuItem);

		fileMenu.append(accelGroup.createMenuItem("Save", Keysyms.GDK_s, ModifierType.CONTROL_MASK, {
			
		}));

		fileMenu.append(accelGroup.createMenuItem("Save As...", Keysyms.GDK_s,
			ModifierType.CONTROL_MASK | ModifierType.SHIFT_MASK, {
			
		}));

		fileMenu.append(new SeparatorMenuItem);

		auto nextTabItem = accelGroup.createMenuItem("Switch to next tab",
				Keysyms.GDK_Tab, ModifierType.CONTROL_MASK, {
			project.commitCurrent();
			canvasTabs.setCurrentPage(cast(int)((selectedProject + 1) % projects.length));
		});
		fileMenu.append(nextTabItem);

		auto prevTabItem = accelGroup.createMenuItem("Switch to previous tab",
				Keysyms.GDK_Tab, ModifierType.CONTROL_MASK | ModifierType.SHIFT_MASK, {
			project.commitCurrent();
			canvasTabs.setCurrentPage(cast(int)((selectedProject + projects.length - 1) % projects.length));
		});
		fileMenu.append(prevTabItem);

		fileMenu.append(new SeparatorMenuItem);

		fileMenu.append(accelGroup.createMenuItem("Quit", Keysyms.GDK_q, ModifierType.CONTROL_MASK, {
			close();
		}));

		auto edit = new MenuItem("Edit");
		auto editMenu = new Menu;
		edit.setSubmenu(editMenu);
		menubar.append(edit);

		editMenu.append(accelGroup.createMenuItem("Undo", Keysyms.GDK_z, ModifierType.CONTROL_MASK, {
			project.undo();
		}));

		editMenu.append(accelGroup.createMenuItem("Redo", Keysyms.GDK_z,
			ModifierType.CONTROL_MASK | ModifierType.SHIFT_MASK, {
			project.redo();
		}));

		editMenu.append(new SeparatorMenuItem);

		editMenu.append(accelGroup.createMenuItem("Cut", Keysyms.GDK_x, ModifierType.CONTROL_MASK, {

		}));

		editMenu.append(accelGroup.createMenuItem("Copy", Keysyms.GDK_c, ModifierType.CONTROL_MASK, {
		}));

		editMenu.append(accelGroup.createMenuItem("Paste", Keysyms.GDK_v, ModifierType.CONTROL_MASK, {
			
		}));

		editMenu.append(new SeparatorMenuItem);

		editMenu.append(accelGroup.createMenuItem("Deselect", Keysyms.GDK_Escape, cast(ModifierType) 0, {
			auto edit = project.startEdit("Deselect");
			project.edit(edit, (Project.EditData data) {
				if (data.selection.empty) {
					project.cancel(edit);
				}
				data.selection.clear();
			});
			project.commit(edit);
		}));

		menubar.append(new Effects);

		auto view = new MenuItem("View");
		auto viewMenu = new Menu;
		view.setSubmenu(viewMenu);
		menubar.append(view);

		DockMenuItem[] viewItems;

		view.addOnActivate((MenuItem) {
			foreach (item; viewItems) {
				item.update();
			}
		});

		vbox.packStart(menubar, false, false, 0);

		DockItem canvasContainer = new DockItem("canvas", "Canvas",
			GdlDockItemBehavior.LOCKED
			| GdlDockItemBehavior.CANT_CLOSE
			| GdlDockItemBehavior.NO_GRIP);
		canvasContainer.add(canvasTabs);
		dock.addItem(canvasContainer, GdlDockPlacement.CENTER);

		DockItem toolbox = new DockItem("toolbox", "Toolbox", GdlDockItemBehavior.CANT_ICONIFY);
		toolbox.add(new Toolbox);

		DockMenuItem toolboxItem = new DockMenuItem("Toolbox", toolbox);
		viewItems ~= toolboxItem;
		viewMenu.append(toolboxItem);

		DockItem history = new DockItem("history", "History", GdlDockItemBehavior.CANT_ICONIFY);
		History prev;
		History[Project] histories;
		histories[project] = new History(project);
		history.add(prev = histories[project]);
		onSelectedProjectChanged.connect((size_t) {
			if (project !in histories) {
				histories[project] = new History(project);
			}
			history.remove(prev);
			history.add(prev = histories[project]);
			history.showAll();
		});

		DockMenuItem historyItem = new DockMenuItem("History", history);
		viewItems ~= historyItem;
		viewMenu.append(historyItem);

		DockItem colors = new DockItem("colors", "Colors", GdlDockItemBehavior.CANT_ICONIFY);
		colors.add(new Colors);

		DockMenuItem colorsItem = new DockMenuItem("Colors", colors);
		viewItems ~= colorsItem;
		viewMenu.append(colorsItem);

		DockItem layers = new DockItem("layers", "Layers", GdlDockItemBehavior.CANT_ICONIFY);
		layers.add(new Layers);

		DockMenuItem layersItem = new DockMenuItem("Layers", layers);
		viewItems ~= layersItem;
		viewMenu.append(layersItem);

		canvasContainer.dock(toolbox, GdlDockPlacement.LEFT, null);
		canvasContainer.dock(history, GdlDockPlacement.RIGHT, null);
		history.dock(colors, GdlDockPlacement.BOTTOM, null);
		colors.dock(layers, GdlDockPlacement.BOTTOM, null);

		bool hasFile = layout.loadFromFile("layout.xml");
		if (hasFile) {
			layout.loadLayout(currentLayout);
		}

		vbox.packStart(dock, true, true, 0);

		dock.addOnLayoutChanged((Dock) {
			layout.saveLayout(currentLayout);
		});

		addOnKeyPress((GdkEventKey* ev, Widget) {
			if ((ev.keyval == Keysyms.GDK_Tab || ev.keyval == Keysyms.GDK_ISO_Left_Tab)
					&& (ev.state & ModifierType.CONTROL_MASK)) {
				if (ev.state & ModifierType.SHIFT_MASK) {
					prevTabItem.activate();
				}
				else {
					nextTabItem.activate();
				}
				return true;
			}

			if (ev.state & ModifierType.CONTROL_MASK) {
				if (ev.keyval >= Keysyms.GDK_1 && ev.keyval <= Keysyms.GDK_8) {
					int num = ev.keyval - Keysyms.GDK_1;
					canvasTabs.setCurrentPage(min(max(num, 0), projects.length - 1));
					return true;
				}
				else if (ev.keyval == Keysyms.GDK_9) {
					canvasTabs.setCurrentPage(cast(int) projects.length - 1);
					return true;
				}
			}

			return false;
		});

		showAll();
	}

	override bool windowDelete(Event ev, Widget) {
		layout.saveToFile("layout.xml");
		DialogResult res = DialogDescription("Unsaved work", [
			
		], ["Save", "Save All", "Don't Save", "Don't Save Any", "Cancel"]).showDialog();
		Main.quit();
		return true;
	}

	void newProject() {
		DialogResult res = DialogDescription("New", [
			DialogGroup("Pixel size", [
				DialogRow([
					new DialogLabel("Width:"),
					new DialogTextInput("width", "800"),
					new DialogLabel("pixels"),
				]),
				DialogRow([
					new DialogLabel("Height:"),
					new DialogTextInput("height", "600"),
					new DialogLabel("pixels"),
				]),
			]),
			DialogGroup("Print size", [

			]),
		], ["OK", "Cancel"], (string[string] data) {
			bool enabled = true;
			if (data["width"].length == 0 || !data["width"].all!(x => x >= '0' && x <= '9')) {
				enabled = false;
			}
			if (data["height"].length == 0 || !data["height"].all!(x => x >= '0' && x <= '9')) {
				enabled = false;
			}
			return [enabled, true];
		}).showDialog();
	}

}

PaintedWindow mainWin;

public:

DialogResult showDialog(DialogDescription desc) {
	DialogResult result;

	Dialog dlg = new Dialog(desc.title, mainWin, GtkDialogFlags.MODAL,
		desc.buttons, iota(0, desc.buttons.length).map!(x => cast(ResponseType) x).array);

	VBox contentArea = dlg.getContentArea();

	Box inner = new Box(GtkOrientation.VERTICAL, 4);
	inner.setMarginTop(4);
	inner.setMarginLeft(4);
	inner.setMarginRight(4);
	inner.setMarginBottom(4);

	string[string] data;

	void updateSensitivities() {
		bool[] values;
		if (desc.validate !is null) {
			values = desc.validate(data);
		}
		else {
			values = true.repeat(desc.buttons.length).array;
		}
		foreach (i; 0 .. cast(int) desc.buttons.length) {
			Widget btn = dlg.getWidgetForResponse(i);
			btn.setSensitive(values[i]);
		}
	}

	foreach (group; desc.groups) {
		if (group.title != "") {
			Box titleBox = new Box(GtkOrientation.HORIZONTAL, 4);
			titleBox.packStart(new Label(group.title), false, false, 0);
			Box separator = new Box(GtkOrientation.VERTICAL, 0);
			separator.packStart(new Separator(GtkOrientation.HORIZONTAL), true, false, 0);
			titleBox.packStart(separator, true, true, 0);
			inner.packStart(titleBox, false, false, 0);
		}

		foreach (value; group.values) {
			Box container = new Box(GtkOrientation.HORIZONTAL, 4);
			foreach (segment; value.segments) {
				(){
					auto inp = cast(DialogInputSegment) segment;
					string key = inp ? inp.key : "";
					if (key != "") {
						data[key] = inp.defaultValue;
					}
					segment.packageAddTo(container, (string value) {
						if (key != "") {
							data[key] = value;
						}
						updateSensitivities();
					});
				}();
			}
			inner.packStart(container, false, false, 0);
		}
	}

	updateSensitivities();

	contentArea.packStart(inner, true, true, 0);

	dlg.addOnResponse((int response, Dialog) {
		if (response >= 0) {
			result.button = response;
			dlg.destroy();
		}
		else {
			result.button = -1;
		}
	});

	dlg.showAll();
	dlg.run();

	return result;
}

void initUI(string[] args) {
	import painted.builtin.tools : initBuiltinTools;
	import painted.builtin.effects : initBuiltinEffects;

	Main.init(args);
	mainWin = new PaintedWindow;
	initBuiltinTools();
	initBuiltinEffects();
	Main.run();
}
