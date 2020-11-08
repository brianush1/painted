module gdl.DockPaned;

private import gdl.DockItem;
private import gdl.c.functions;
public  import gdl.c.types;
private import glib.ConstructionException;
private import gobject.ObjectG;
private import gtk.Widget;


/** */
public class DockPaned : DockItem
{
	/** the main Gtk struct */
	protected GdlDockPaned* gdlDockPaned;

	/** Get the main Gtk struct */
	public GdlDockPaned* getDockPanedStruct(bool transferOwnership = false)
	{
		if (transferOwnership)
			ownedRef = false;
		return gdlDockPaned;
	}

	/** the main Gtk struct as a void* */
	protected override void* getStruct()
	{
		return cast(void*)gdlDockPaned;
	}

	/**
	 * Sets our main struct and passes it to the parent class.
	 */
	public this (GdlDockPaned* gdlDockPaned, bool ownedRef = false)
	{
		this.gdlDockPaned = gdlDockPaned;
		super(cast(GdlDockItem*)gdlDockPaned, ownedRef);
	}


	/** */
	public static GType getType()
	{
		return gdl_dock_paned_get_type();
	}

	/**
	 * Creates a new manual #GdlDockPaned widget. This function is seldom useful as
	 * such widget is normally created and destroyed automatically when needed by
	 * the master.
	 *
	 * Params:
	 *     orientation = the pane's orientation.
	 *
	 * Returns: a new #GdlDockPaned.
	 *
	 * Throws: ConstructionException GTK+ fails to create the object.
	 */
	public this(GtkOrientation orientation)
	{
		auto __p = gdl_dock_paned_new(orientation);

		if(__p is null)
		{
			throw new ConstructionException("null returned by new");
		}

		this(cast(GdlDockPaned*) __p);
	}
}
