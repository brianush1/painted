module painted.logic;
import painted.utils;
import graphics.canvas;
import std.stdio;
import std.path;
import std.range;
import std.file;
import std.algorithm;
import std.conv;
import std.array;
import std.exception;
import std.string;
import std.typecons;
import std.digest.sha;
import std.digest;

private:

abstract class ContentStore {

	abstract Ref add(const(ubyte)[] data);

	abstract immutable(ubyte)[] get(Ref reff);

	abstract void remove(Ref reff);

	abstract Ref[] list();

	abstract void head(Ref reff);

	abstract Ref head();

}

string hex(Ref reff) {
	return reff.toHexString().idup;
}

// TODO: replace with a more reliable storage mechanism
final class FileStore : ContentStore {

	private string path;

	this(string path) {
		this.path = path;
		if (!exists(path)) {
			mkdir(path);
		}
	}

	override Ref add(const(ubyte)[] obj) {
		Ref hash = sha1Of(obj);
		string filePath = path ~ "/" ~ hash.hex();
		if (!exists(filePath)) {
			File file = File(filePath, "wb");
			file.rawWrite(obj);
			file.close();
		}
		return hash;
	}

	override immutable(ubyte)[] get(Ref reff) {
		File file = File(path ~ "/" ~ reff.hex(), "rb");
		file.seek(0, SEEK_END);
		ulong length = file.tell();
		file.rewind();
		ubyte[] buffer = new ubyte[length];
		file.rawRead(buffer);
		file.close();
		return buffer.assumeUnique;
	}

	override void remove(Ref reff) {
		std.file.remove(path ~ "/" ~ reff.hex());
	}

	override Ref[] list() {
		Ref[] result;
		foreach (DirEntry entry; dirEntries(path, SpanMode.shallow)) {
			string hexedName = baseName(entry.name);
			if (hexedName.length == 40) {
				result.assumeSafeAppend ~= hexedName.chunks(2)
					.map!(x => x.parse!ubyte(16U)).array.to!Ref();
			}
		}
		return result;
	}

	override void head(Ref reff) {
		File file = File(path ~ "/head", "wb");
		file.writeln(reff.hex());
		file.close();
	}

	override Ref head() {
		File file = File(path ~ "/head", "rb");
		Ref result = file.readln().chomp.chunks(2)
			.map!(x => x.parse!ubyte(16)).array.to!Ref();
		file.close();
		return result;
	}

}

void invalidVersion() {
	throw new Exception("invalid version");
}

T read(T)(ref const(ubyte)[] data) {
	import std.traits : Unqual;

	static if (is(T == K[], K)) {
		Unqual!K[] result;
		size_t length = cast(size_t) read!ulong(data);
		foreach (i; 0 .. length) {
			result.assumeSafeAppend ~= read!(Unqual!K)(data);
		}
		return cast(T) result;
	}
	else static if (is(T == Nullable!K, K)) {
		bool isNull = read!bool(data);
		if (!isNull) {
			return T(read!K(data));
		}
		else {
			return T.init;
		}
	}
	else {
		T result = *cast(T*) data.ptr;
		data = data[T.sizeof .. $];
		return result;
	}
}

void write(T)(ref ubyte[] data, T value) {
	import std.traits : Unqual, isBasicType;

	static if (is(T == K[], K)) {
		write!ulong(data, value.length);
		static if (isBasicType!K) {
			data.length += value.length * K.sizeof;
			Unqual!K[] slice = cast(Unqual!K[]) data[$ - value.length * K.sizeof .. $];
			slice[] = value;
		}
		else {
			foreach (v; value) {
				write(data, v);
			}
		}
	}
	else static if (is(T == Nullable!K, K)) {
		write!bool(data, value.isNull);
		if (!value.isNull) {
			write!K(data, value.get);
		}
	}
	else {
		data.length += T.sizeof;
		*cast(Unqual!T*)(data.ptr + data.length - T.sizeof) = cast(Unqual!T) value;
	}
}

Path readPath(ref const(ubyte)[] data) {
	uint numSub = data.read!uint();
	Path path = new Path;
	foreach (i; 0 .. numSub) {
		double startX = data.read!double();
		double startY = data.read!double();
		path.moveTo(startX, startY);
		auto lines = data.read!(double[6][]);
		foreach (line; lines) {
			path.bezierCurveTo(line[0], line[1], line[2], line[3], line[4], line[5]);
		}
		bool closed = data.read!bool();
		if (closed) {
			path.closePath();
		}
	}
	return path;
}

void writePath(ref ubyte[] data, const(Path) path) {
	data.write!uint(cast(uint) path.getSubpaths.length);
	foreach (subpath; path.getSubpaths) {
		data.write(subpath.startX);
		data.write(subpath.startY);
		data.write(subpath.lines);
		data.write(subpath.closed);
	}
}

abstract class Storable {

	abstract const(ubyte)[] serialize() const;

	abstract void deserialize(const(ubyte)[] data);

	abstract void markRefs(ContentStore store, ref Ref[] refs) const;

	Ref store(ContentStore store) const {
		Ref reff = store.add(serialize());
		(cast(Storable[Ref]) cache)[reff] = cast(Storable) this;
		return reff;
	}

}

void markAndContinue(T)(ContentStore store, Ref reff, ref Ref[] refs) if (is(T : Storable)) {
	refs.assumeSafeAppend ~= reff;
	load!T(store, reff).markRefs(store, refs);
}

// TODO: weak references
const(Storable)[Ref] cache;

package:

alias Ref = ubyte[20];

const(T) load(T)(ContentStore store, Ref reff) if (is(T : Storable)) {
	if (auto s = reff in cache) {
		return cast(const(T))*s;
	}
	else {
		T result = new T;
		result.deserialize(store.get(reff));
		(cast(Storable[Ref]) cache)[reff] = result;
		return result;
	}
}

enum BasicBlendOp : ushort {
	Normal,
}

final class ObjBlendOp : Storable {
	private BasicBlendOp op;

	override const(ubyte)[] serialize() const {
		ubyte[] data;
		data.write!uint(0);
		data.write!BasicBlendOp(op);
		return data;
	}

	override void deserialize(const(ubyte)[] data) {
		uint v = data.read!uint();
		if (v == 0) {
			op = data.read!BasicBlendOp();
		}
		else {
			invalidVersion();
		}
	}

	override void markRefs(ContentStore store, ref Ref[] refs) const {}
}

final class ObjBitmap : Storable {

	Color[] content;

	override const(ubyte)[] serialize() const {
		ubyte[] data;
		data.write!uint(0);
		data.write(content);
		return data;
	}

	override void deserialize(const(ubyte)[] data) {
		uint v = data.read!uint();
		if (v == 0) {
			content = data.read!(Color[])();
		}
		else {
			invalidVersion();
		}
	}

	override void markRefs(ContentStore store, ref Ref[] refs) const {}

}

enum LayerType : ushort {
	Bitmap,
}

final class ObjLayer : Storable {
	string name;

	double opacity;

	Ref blendOp;

	LayerType type;

	Ref content;

	override const(ubyte)[] serialize() const {
		ubyte[] data;
		data.write!uint(0);
		data.write!string(name);
		data.write!double(opacity);
		data.write!Ref(blendOp);
		data.write!LayerType(type);
		data.write!Ref(content);
		return data;
	}

	override void deserialize(const(ubyte)[] data) {
		uint v = data.read!uint();
		if (v == 0) {
			name = data.read!string();
			opacity = data.read!double();
			blendOp = data.read!Ref();
			type = data.read!LayerType();
			content = data.read!Ref();
		}
		else {
			invalidVersion();
		}
	}

	override void markRefs(ContentStore store, ref Ref[] refs) const {
		refs.assumeSafeAppend ~= content; // we assume content isn't gonna have any children refs
		// we wanna avoid loading images into memory since they're pretty large

		markAndContinue!ObjBlendOp(store, blendOp, refs);
	}
}

final class ObjSnapshot : Storable {
	/** The action that was taken to create this snapshot */
	string name;

	/** The list of layers in the snapshot, ordered from back to front */
	Ref[] layers;

	uint width;

	uint height;

	Path selection = new Path;

	override const(ubyte)[] serialize() const {
		ubyte[] data;
		data.write!uint(0);
		data.write!string(name);
		data.write(layers);
		data.write!uint(width);
		data.write!uint(height);
		data.writePath(selection);
		return data;
	}

	override void deserialize(const(ubyte)[] data) {
		uint v = data.read!uint();
		if (v == 0) {
			name = data.read!string();
			layers = data.read!(Ref[])();
			width = data.read!uint();
			height = data.read!uint();
			selection = data.readPath();
		}
		else {
			invalidVersion();
		}
	}

	override void markRefs(ContentStore store, ref Ref[] refs) const {
		foreach (layer; layers) {
			markAndContinue!ObjLayer(store, layer, refs);
		}
	}
}

final class ObjProject : Storable {
	/** The list of snapshots in this history, ordered from least to most recent */
	const(Ref)[] history;

	/** The list of snapshots in this history that have been undone, ordered from least to most recent */
	const(Ref)[] future;

	override const(ubyte)[] serialize() const {
		ubyte[] data;
		data.write!uint(0);
		data.write(history);
		data.write(future);
		return data;
	}

	override void deserialize(const(ubyte)[] data) {
		uint v = data.read!uint();
		if (v == 0) {
			history = data.read!(const(Ref)[])();
			future = data.read!(const(Ref)[])();
		}
		else {
			invalidVersion();
		}
	}

	override void markRefs(ContentStore store, ref Ref[] refs) const {
		foreach (v; history) {
			markAndContinue!ObjSnapshot(store, v, refs);
		}
		foreach (v; future) {
			markAndContinue!ObjSnapshot(store, v, refs);
		}
	}
}

struct ProjectOptions {
	uint width;
	uint height;
}

final class ProjectWrapper {

	ContentStore store;

	Ref workingProject;

	private this() {}

	static ProjectWrapper create(string path, ProjectOptions opts) {
		auto result = new ProjectWrapper;
		result.store = new FileStore(path);
		ObjProject proj = new ObjProject;

		ObjSnapshot first = new ObjSnapshot;
		first.name = "New image";
		first.width = opts.width;
		first.height = opts.height;

		ObjLayer layer = new ObjLayer;
		layer.name = "Background";
		layer.opacity = 1;
		layer.type = LayerType.Bitmap;

		ObjBlendOp blendOp = new ObjBlendOp;
		blendOp.op = BasicBlendOp.Normal;
		layer.blendOp = blendOp.store(result.store);

		ObjBitmap bitmap = new ObjBitmap;
		bitmap.content = new Color[opts.width * cast(size_t) opts.height];
		bitmap.content[] = Color(255, 255, 255, 255);
		layer.content = bitmap.store(result.store);

		first.layers.assumeSafeAppend ~= layer.store(result.store);

		proj.history ~= first.store(result.store);

		result.workingProject = proj.store(result.store);
		result.store.head = result.workingProject;

		return result;
	}

	static ProjectWrapper load(string path) {
		auto result = new ProjectWrapper;

		result.store = new FileStore(path);

		result.workingProject = result.store.head;

		return result;
	}

	void gc() {
		import core.memory : GC;

		Ref[] refs;
		markAndContinue!ObjProject(store, workingProject, refs);
		markAndContinue!ObjProject(store, store.head, refs);
		bool[Ref] refSet;
		foreach (reff; refs) {
			refSet[reff] = true;
		}
		foreach (reff; store.list) {
			if (reff !in refSet) {
				cache.remove(reff);
				store.remove(reff);
			}
		}
		GC.collect();
	}

	void save() {
		store.head = workingProject;
		gc();
	}

}
