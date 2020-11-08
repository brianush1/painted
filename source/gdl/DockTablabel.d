module gdl.DockTablabel;

private import gdk.Event;
private import gdl.DockItem;
private import gdl.c.functions;
public  import gdl.c.types;
private import glib.ConstructionException;
private import gobject.ObjectG;
private import gobject.Signals;
private import gtk.Bin;
private import gtk.BuildableIF;
private import gtk.BuildableT;
private import gtk.Widget;
private import std.algorithm;


/** */
public class DockTablabel : Bin
{
	/** the main Gtk struct */
	protected GdlDockTablabel* gdlDockTablabel;

	/** Get the main Gtk struct */
	public GdlDockTablabel* getDockTablabelStruct(bool transferOwnership = false)
	{
		if (transferOwnership)
			ownedRef = false;
		return gdlDockTablabel;
	}

	/** the main Gtk struct as a void* */
	protected override void* getStruct()
	{
		return cast(void*)gdlDockTablabel;
	}

	/**
	 * Sets our main struct and passes it to the parent class.
	 */
	public this (GdlDockTablabel* gdlDockTablabel, bool ownedRef = false)
	{
		this.gdlDockTablabel = gdlDockTablabel;
		super(cast(GtkBin*)gdlDockTablabel, ownedRef);
	}


	/** */
	public static GType getType()
	{
		return gdl_dock_tablabel_get_type();
	}

	/**
	 * Creates a new GDL tab label widget.
	 *
	 * Deprecated: Use a #GtkLabel instead
	 *
	 * Params:
	 *     item = The dock item that associated with this label widget.
	 *
	 * Returns: a new #GdlDockTablabel.
	 *
	 * Throws: ConstructionException GTK+ fails to create the object.
	 */
	public this(DockItem item)
	{
		auto __p = gdl_dock_tablabel_new((item is null) ? null : item.getDockItemStruct());

		if(__p is null)
		{
			throw new ConstructionException("null returned by new");
		}

		this(cast(GdlDockTablabel*) __p);
	}

	alias activate = Widget.activate;

	/**
	 * Set the widget in "activated" state.
	 */
	public void activate()
	{
		gdl_dock_tablabel_activate(gdlDockTablabel);
	}

	/**
	 * Set the widget in "deactivated" state.
	 */
	public void deactivate()
	{
		gdl_dock_tablabel_deactivate(gdlDockTablabel);
	}

	/**
	 * This signal is emitted when the user clicks on the label.
	 *
	 * Params:
	 *     event = A #GdkEvent
	 */
	gulong addOnButtonPressedHandle(void delegate(Event, DockTablabel) dlg, ConnectFlags connectFlags=cast(ConnectFlags)0)
	{
		return Signals.connect(this, "button-pressed-handle", dlg, connectFlags ^ ConnectFlags.SWAPPED);
	}
}
