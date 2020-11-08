module gdl.DockBar;

private import gdl.c.functions;
public  import gdl.c.types;
private import glib.ConstructionException;
private import gobject.ObjectG;
private import gtk.Box;
private import gtk.Style;
private import gtk.BuildableIF;
private import gtk.BuildableT;
private import gtk.OrientableIF;
private import gtk.OrientableT;
private import gtk.Widget;


/** */
public class DockBar : Box
{
	/** the main Gtk struct */
	protected GdlDockBar* gdlDockBar;

	/** Get the main Gtk struct */
	public GdlDockBar* getDockBarStruct(bool transferOwnership = false)
	{
		if (transferOwnership)
			ownedRef = false;
		return gdlDockBar;
	}

	/** the main Gtk struct as a void* */
	protected override void* getStruct()
	{
		return cast(void*)gdlDockBar;
	}

	/**
	 * Sets our main struct and passes it to the parent class.
	 */
	public this (GdlDockBar* gdlDockBar, bool ownedRef = false)
	{
		this.gdlDockBar = gdlDockBar;
		super(cast(GtkBox*)gdlDockBar, ownedRef);
	}


	/** */
	public static GType getType()
	{
		return gdl_dock_bar_get_type();
	}

	/**
	 * Creates a new GDL dock bar. If a #GdlDockObject is used, the dock bar will
	 * be associated with the master of this object.
	 *
	 * Params:
	 *     master = The associated #GdlDockMaster or #GdlDockObject object
	 *
	 * Returns: The newly created dock bar.
	 *
	 * Throws: ConstructionException GTK+ fails to create the object.
	 */
	public this(ObjectG master)
	{
		auto __p = gdl_dock_bar_new((master is null) ? null : master.getObjectGStruct());

		if(__p is null)
		{
			throw new ConstructionException("null returned by new");
		}

		this(cast(GdlDockBar*) __p);
	}

	alias getStyle = Widget.getStyle;

	/**
	 * Retrieves the style of the @dockbar.
	 *
	 * Returns: the style of the @docbar
	 */
	public GdlDockBarStyle getStyle()
	{
		return gdl_dock_bar_get_style(gdlDockBar);
	}

	/**
	 * Set the style of the @dockbar.
	 *
	 * Params:
	 *     style = the new style
	 */
	public void setStyle(GdlDockBarStyle style)
	{
		gdl_dock_bar_set_style(gdlDockBar, style);
	}
}
