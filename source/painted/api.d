module painted.api;
import painted.utils;
import painted.logic;
public import painted.logic : LayerType;
public import painted.ui : showDialog;
import graphics.canvas;
import std.exception;
import std.algorithm;
import std.typecons;
import std.array;
import std.uuid;
import gtk.Box;

package void packageAddTo(DialogSegment seg, Box container, void delegate(string) update) {
	seg.addTo(container, update);
}

abstract class DialogSegment {

	protected abstract void addTo(Box container, void delegate(string) update);

}

final class DialogLabel : DialogSegment {

	string value;

	this(string value) {
		this.value = value;
	}

	override void addTo(Box container, void delegate(string) update) {
		import gtk.Label : Label;

		Label label = new Label(value);
		container.packStart(label, false, false, 0);
	}

}

abstract class DialogInputSegment : DialogSegment {

	string key;

	string defaultValue;

	this(string key, string defaultValue) {
		this.key = key;
		this.defaultValue = defaultValue;
	}

}

final class DialogTextInput : DialogInputSegment {

	this(string key, string defaultValue) {
		super(key, defaultValue);
	}

	override void addTo(Box container, void delegate(string) update) {
		import gtk.Entry : Entry;

		Entry entry = new Entry();
		entry.setText(defaultValue);
		entry.addOnChanged((EditableIF) {
			update(entry.getBuffer().getText());
		});
		container.packStart(entry, false, false, 0);
	}

}

final class DialogCheckbox : DialogInputSegment {

	this(string key, string defaultValue) {
		super(key, defaultValue);
	}

	this(string key, bool defaultValue) {
		super(key, defaultValue ? "true" : "false");
	}

	override void addTo(Box container, void delegate(string) update) {
		
	}

}

enum FileSelection {
	Open,
	Save,
}

final class DialogFileSelect : DialogInputSegment {

	const(FileSelection) sel;

	this(string key, FileSelection sel) {
		super(key, "");
		this.sel = sel;
	}

}

struct DialogRow {
	DialogSegment[] segments;
}

struct DialogGroup {
	string title;
	DialogRow[] values;
}

struct DialogDescription {
	string title;
	DialogGroup[] groups;
	string[] buttons;
	bool[] delegate(string[string]) validate;
}

struct DialogResult {
	string[string] values;

	/** The index of the button that was pressed to finish the dialog.
	May be -1 in case the dialog was closed through the window manager */
	int button;
}

final class Layer {
	string name;
	double opacity;
	LayerType type;
	const(Color)[] bitmap;
}

final class Project {
	private ProjectWrapper wrapper;
	private string filename;

	size_t selectedLayer = 0;
	double zoomScale = 1;
	int viewX = 0;
	int viewY = 0;

	private this() {}

	static Project create(string filename, uint width, uint height) {
		Project result = new Project;
		result.wrapper = ProjectWrapper.create(filename, ProjectOptions(width, height));
		result.filename = filename;
		return result;
	}

	static Project load(string filename) {
		Project result = new Project;
		result.wrapper = ProjectWrapper.load(filename);
		result.filename = filename;
		return result;
	}

	private const(ObjSnapshot) now() {
		auto proj = wrapper.store.load!ObjProject(wrapper.workingProject);
		return wrapper.store.load!ObjSnapshot(proj.history[$ - 1]);
	}

	uint width() {
		return now.width;
	}

	uint height() {
		return now.height;
	}

	Signal!(string, int) historyAdded;
	Signal!int historyUndoRedo;

	const(string)[] history() {
		const(ObjProject) proj = wrapper.store.load!ObjProject(wrapper.workingProject);
		return proj.history.map!(x => wrapper.store.load!ObjSnapshot(x).name).array;
	}

	const(string)[] future() {
		const(ObjProject) proj = wrapper.store.load!ObjProject(wrapper.workingProject);
		return proj.future.map!(x => wrapper.store.load!ObjSnapshot(x).name).array;
	}

	class Edit {
		private size_t layerIndex;
		private immutable(Color)[] original;
		private Color[] data;
		private ObjSnapshot next;
		private Ref[] newLayers;
		private ObjLayer newLayer;
		private ObjBitmap newBitmap;
		private Path originalSelection;
		private Path selection;
	}

	private Edit current;

	Edit startEdit(string action) {
		return startEdit(selectedLayer, action);
	}

	Edit startEdit(size_t layerIndex, string action) {
		ObjSnapshot next = new ObjSnapshot;
		next.name = action;
		next.width = now.width;
		next.height = now.height;
		Ref[] newLayers = now.layers.dup;
		next.layers = newLayers;
		Path newSelection = now.selection.clone();
		next.selection = newSelection;
		auto layerRef = now.layers[layerIndex];
		const(ObjLayer) oldLayer = wrapper.store.load!ObjLayer(layerRef);
		ObjLayer newLayer = new ObjLayer;
		newLayer.name = oldLayer.name;
		newLayer.opacity = oldLayer.opacity;
		newLayer.blendOp = oldLayer.blendOp;
		newLayer.type = oldLayer.type;
		if (oldLayer.type == LayerType.Bitmap) {
			const(ObjBitmap) oldBitmap = wrapper.store.load!ObjBitmap(oldLayer.content);
			ObjBitmap newBitmap = new ObjBitmap;
			Color[] data = oldBitmap.content.dup;
			Edit edit = new Edit;
			edit.layerIndex = layerIndex;
			edit.original = oldBitmap.content.assumeUnique;
			edit.data = data;
			edit.next = next;
			edit.newLayers = newLayers;
			edit.newLayer = newLayer;
			edit.newBitmap = newBitmap;
			edit.originalSelection = now.selection.clone();
			edit.selection = newSelection;
			current = edit;
			return edit;
		}
		else {
			assert(0);
		}
	}

	struct EditData {
		immutable(Surface) originalSurface;
		immutable(Path) originalSelection;

		Surface surface;
		Path selection;
	}

	void edit(Edit edit, void delegate(EditData data) editor) {
		if (current is null || current !is edit)
			return;
		EditData data = EditData(
			immutable(Surface)(current.original, width, height),
			cast(immutable(Path)) edit.originalSelection,
			Surface(current.data, width, height),
			current.selection,
		);
		editor(data);
	}

	void commit(Edit edit) {
		if (current is null || current !is edit)
			return;
		commitCurrent();
	}

	void cancel(Edit edit) {
		if (current is null || current !is edit)
			return;
		current = null;
	}

	void commitCurrent() {
		if (current !is null) {
			current.newBitmap.content = current.data;
			current.newLayer.content = current.newBitmap.store(wrapper.store);

			current.newLayers[current.layerIndex] = current.newLayer.store(wrapper.store);
			Ref nextRef = current.next.store(wrapper.store);
			auto oldProject = wrapper.store.load!ObjProject(wrapper.workingProject);
			ObjProject newProject = new ObjProject;
			newProject.history = oldProject.history ~ nextRef;
			newProject.future = [];
			wrapper.workingProject = newProject.store(wrapper.store);
			auto next = current.next;
			current = null;
			historyAdded.emit(next.name, cast(int) newProject.history.length);
		}
	}

	/** If working is set to true, layers that are currently being edited
	which have not yet been committed will return their current contents
	rather than their most recently committed contents */
	Layer[] getLayers(bool working = false) {
		Layer[] result;
		foreach (layerRef; now.layers) {
			const(ObjLayer) objLayer = wrapper.store.load!ObjLayer(layerRef);
			Layer layer = new Layer;
			layer.name = objLayer.name;
			layer.opacity = objLayer.opacity;
			layer.type = objLayer.type;
			if (layer.type == LayerType.Bitmap) {
				if (working && current !is null) {
					layer.bitmap = current.data;
				}
				else {
					layer.bitmap = wrapper.store.load!ObjBitmap(objLayer.content).content;
				}
			}
			else {
				assert(0);
			}
			result.assumeSafeAppend ~= layer;
		}
		return result;
	}

	const(Path) getSelection(bool working = false) {
		if (working && current !is null) {
			return current.selection;
		}
		else {
			return now.selection;
		}
	}

	void save() {
		wrapper.save();
	}

	bool undo() {
		commitCurrent();

		auto oldProject = wrapper.store.load!ObjProject(wrapper.workingProject);
		if (oldProject.history.length > 1) {
			ObjProject newProject = new ObjProject;
			newProject.history = oldProject.history[0 .. $ - 1];
			newProject.future = oldProject.history[$ - 1] ~ oldProject.future;
			wrapper.workingProject = newProject.store(wrapper.store);
			historyUndoRedo.emit(cast(int) newProject.history.length);
			return true;
		}
		else {
			return false;
		}
	}

	bool redo() {
		commitCurrent();

		auto oldProject = wrapper.store.load!ObjProject(wrapper.workingProject);
		if (oldProject.future.length > 0) {
			ObjProject newProject = new ObjProject;
			newProject.history = oldProject.history ~ oldProject.future[0];
			newProject.future = oldProject.future[1 .. $];
			wrapper.workingProject = newProject.store(wrapper.store);
			historyUndoRedo.emit(cast(int) newProject.history.length);
			return true;
		}
		else {
			return false;
		}
	}
}

struct Signal(T...) {

	private void delegate(T)[] slots;

	void emit(T args) {
		foreach (slot; slots) {
			slot(args);
		}
	}

	UUID connect(void delegate(T) handler) {
		slots.assumeSafeAppend ~= handler;
		return randomUUID();
	}

	void disconnect(UUID id) {
		// TODO: this
	}

}

enum MouseButton {
	Left,
	Right,
}

enum Target {
	None,
	PixelCenter,
	PixelCorner,
}

enum Modifiers {
	None = 0,
	Ctrl = 1,
	Shift = 2,
	Alt = 4,
}

enum SelectionBehavior {
	Normal,
	Modifier,
}

abstract class Tool {
	ubyte[] iconData;
	string displayName;
	Target target = Target.None;
	SelectionBehavior selectionBehavior = SelectionBehavior.Normal;

	Signal!() onDeselect;
	Signal!() onSelect;

	Signal!(Project, MouseButton, int, int, int, int) onPress;
	Signal!(Project, int, int, int, int, Modifiers) onMove;
	Signal!(Project, MouseButton, int, int, int, int) onRelease;

	Path getPixelHighlightPath() {
		return Path.fromRectangle(-0.5, -0.5, 1, 1);
	}

	final bool selected() {
		return selectedTool is this;
	}

	final void select() {
		project.commitCurrent();

		if (selectedTool is this)
			return;

		if (selectedTool)
			selectedTool.onDeselect.emit();
		_selectedTool = this;
		onSelect.emit();
	}
}

void registerTool(string id, Tool tool) {
	tools ~= tool;
	toolsMap[id] = tool;
	if (!selectedTool) {
		tool.select();
	}
}

Tool tool(string id) {
	return toolsMap[id];
}

abstract class Effect {
	ubyte[] iconData;
	string displayName;

	abstract void apply(immutable(Surface) original, Surface data, Rect rect, const(bool)* isCancelRequested);
}

void registerEffect(string id, Effect effect) {
	effects ~= effect;
}

void refreshPlugins() {
	foreach (handler; refreshHandlers) {
		handler();
	}
}

Tool selectedTool() {
	return _selectedTool;
}

Color color1 = Color(0, 0, 0, 255);
Color color2 = Color(255, 255, 255, 255);

Color preferredColor() {
	return usingSecondary ? color2 : color1;
}

Project[] projects;
private size_t _selectedProject = 0;

size_t selectedProject() {
	return _selectedProject;
}

Signal!size_t onSelectedProjectChanged;

void selectedProject(size_t value) {
	_selectedProject = value;
	onSelectedProjectChanged.emit(value);
}

Project project() {
	return projects[selectedProject];
}

private:

Tool _selectedTool;

package:

bool usingSecondary = false;

Tool[] tools;
Tool[string] toolsMap;

Effect[] effects;

alias RefreshHandler = void delegate();

RefreshHandler[] refreshHandlers;

void addRefreshHandler(RefreshHandler handler) {
	refreshHandlers.assumeSafeAppend ~= handler;
}
