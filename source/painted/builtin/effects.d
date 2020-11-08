module painted.builtin.effects;
import painted.utils;
import painted.api;
import graphics.canvas;
import std.math;

void initBuiltinEffects() {
	registerEffect("grayscale", new class Effect {

		this() {
			displayName = "Grayscale";
			// iconData = cast(ubyte[]) import("images/paintbrush.png");
		}

		override void apply(immutable(Surface) original, Surface data,
			Rect rect, const(bool)* isCancelRequested) {
			foreach (i; 0 .. rect.width) {
				foreach (j; 0 .. rect.height) {
					if (*isCancelRequested) break;
					ubyte value = original[i, j].intensity;
					data[i, j] = Color(value, value, value, original[i, j].a);
				}
			}
		}

	});

	refreshPlugins();
}