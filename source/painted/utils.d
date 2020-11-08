module painted.utils;

align(1) struct Color {
	align(1) uint value;

	this(uint value) {
		this.value = value;
	}

	this(ubyte r, ubyte g, ubyte b, ubyte a) {
		this.r = r;
		this.g = g;
		this.b = b;
		this.a = a;
	}

	ubyte r() const @property { return value & 0xFF; }
	ubyte g() const @property { return (value >> 8) & 0xFF; }
	ubyte b() const @property { return (value >> 16) & 0xFF; }
	ubyte a() const @property { return (value >> 24) & 0xFF; }
	void r(ubyte v) @property { value = (value & ~0x000000FF) | (cast(uint) v << 0); }
	void g(ubyte v) @property { value = (value & ~0x0000FF00) | (cast(uint) v << 8); }
	void b(ubyte v) @property { value = (value & ~0x00FF0000) | (cast(uint) v << 16); }
	void a(ubyte v) @property { value = (value & ~0xFF000000) | (cast(uint) v << 24); }

	ubyte intensity() const @property {
		return cast(ubyte)((7471 * b + 38_470 * g + 19_595 * r) >> 16);
	}
}

static assert(Color.sizeof == 4);

struct Rect {
	uint x;
	uint y;
	uint width;
	uint height;
}

struct Surface {
	Color[] data;
	uint width;
	uint height;
	size_t pitch;

	this(inout(Color[]) data, uint width, uint height, size_t pitch) inout {
		this.data = data;
		this.width = width;
		this.height = height;
		this.pitch = pitch;
	}

	this(inout(Color[]) data, uint width, uint height) inout {
		this.data = data;
		this.width = width;
		this.height = height;
		pitch = width;
	}

	Color opIndex(uint x, uint y) const {
		assert(x < width && y < height);
		return data[y * pitch + x];
	}

	void opIndexAssign(Color color, uint x, uint y) {
		assert(x < width && y < height);
		data[y * pitch + x] = color;
	}

	void copyFrom(const(Surface) other) {
		assert(width == other.width && height == other.height);
		foreach (j; 0 .. height) {
			data[j * pitch .. j * pitch + width] = other.data[j * other.pitch
				.. j * other.pitch + width];
		}
	}
}

double getUnixTime() {
	import std.datetime.systime : SysTime, Clock;
	import std.datetime.interval : Interval;
	import std.datetime.date : DateTime;
	import std.datetime.timezone : UTC;

	return Interval!SysTime(SysTime(DateTime(1970, 1, 1), UTC()), Clock.currTime)
		.length.total!"hnsecs" / 10_000_000.0;
}
