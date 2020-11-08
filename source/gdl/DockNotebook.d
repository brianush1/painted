module gdl.DockNotebook;

private import gdl.DockItem;
private import gdl.c.functions;
public  import gdl.c.types;
private import glib.ConstructionException;
private import gobject.ObjectG;
private import gtk.Widget;


/** */
public class DockNotebook : DockItem
{
	/** the main Gtk struct */
	protected GdlDockNotebook* gdlDockNotebook;

	/** Get the main Gtk struct */
	public GdlDockNotebook* getDockNotebookStruct(bool transferOwnership = false)
	{
		if (transferOwnership)
			ownedRef = false;
		return gdlDockNotebook;
	}

	/** the main Gtk struct as a void* */
	protected override void* getStruct()
	{
		return cast(void*)gdlDockNotebook;
	}

	/**
	 * Sets our main struct and passes it to the parent class.
	 */
	public this (GdlDockNotebook* gdlDockNotebook, bool ownedRef = false)
	{
		this.gdlDockNotebook = gdlDockNotebook;
		super(cast(GdlDockItem*)gdlDockNotebook, ownedRef);
	}


	/** */
	public static GType getType()
	{
		return gdl_dock_notebook_get_type();
	}

	/**
	 * Creates a new manual #GdlDockNotebook widget. This function is seldom useful as
	 * such widget is normally created and destroyed automatically when needed by
	 * the master.
	 *
	 * Returns: The newly created #GdlDockNotebook.
	 *
	 * Throws: ConstructionException GTK+ fails to create the object.
	 */
	public this()
	{
		auto __p = gdl_dock_notebook_new();

		if(__p is null)
		{
			throw new ConstructionException("null returned by new");
		}

		this(cast(GdlDockNotebook*) __p);
	}
}
