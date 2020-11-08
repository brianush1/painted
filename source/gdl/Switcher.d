module gdl.Switcher;

private import gdkpixbuf.Pixbuf;
private import gdl.c.functions;
public  import gdl.c.types;
private import glib.ConstructionException;
private import glib.Str;
private import gobject.ObjectG;
private import gtk.BuildableIF;
private import gtk.BuildableT;
private import gtk.Notebook;
private import gtk.Widget;


/** */
public class Switcher : Notebook
{
	/** the main Gtk struct */
	protected GdlSwitcher* gdlSwitcher;

	/** Get the main Gtk struct */
	public GdlSwitcher* getSwitcherStruct(bool transferOwnership = false)
	{
		if (transferOwnership)
			ownedRef = false;
		return gdlSwitcher;
	}

	/** the main Gtk struct as a void* */
	protected override void* getStruct()
	{
		return cast(void*)gdlSwitcher;
	}

	/**
	 * Sets our main struct and passes it to the parent class.
	 */
	public this (GdlSwitcher* gdlSwitcher, bool ownedRef = false)
	{
		this.gdlSwitcher = gdlSwitcher;
		super(cast(GtkNotebook*)gdlSwitcher, ownedRef);
	}


	/** */
	public static GType getType()
	{
		return gdl_switcher_get_type();
	}

	/**
	 * Creates a new notebook widget with no pages.
	 *
	 * Returns: The newly created #GdlSwitcher
	 *
	 * Throws: ConstructionException GTK+ fails to create the object.
	 */
	public this()
	{
		auto __p = gdl_switcher_new();

		if(__p is null)
		{
			throw new ConstructionException("null returned by new");
		}

		this(cast(GdlSwitcher*) __p);
	}

	/**
	 * Adds a page to a #GdlSwitcher.  A button is created in the switcher, with its
	 * icon taken preferentially from the @stock_id parameter.  If this parameter is
	 * %NULL, then the @pixbuf_icon parameter is used.  Failing that, the
	 * %GTK_STOCK_NEW stock icon is used.  The text label for the button is specified
	 * using the @label parameter.  If it is %NULL then a default incrementally
	 * numbered label is used instead.
	 *
	 * Params:
	 *     page = The page to add to the switcher
	 *     tabWidget = The  to add to the switcher
	 *     label = The label text for the button
	 *     tooltips = The tooltip for the button
	 *     stockId = The stock ID for the button icon
	 *     pixbufIcon = The pixbuf to use for the button icon
	 *     position = The position at which to create the page
	 *
	 * Returns: The index (starting from 0) of the appended page in the notebook, or -1 if function fails
	 */
	public int insertPage(Widget page, Widget tabWidget, string label, string tooltips, string stockId, Pixbuf pixbufIcon, int position)
	{
		return gdl_switcher_insert_page(gdlSwitcher, (page is null) ? null : page.getWidgetStruct(), (tabWidget is null) ? null : tabWidget.getWidgetStruct(), Str.toStringz(label), Str.toStringz(tooltips), Str.toStringz(stockId), (pixbufIcon is null) ? null : pixbufIcon.getPixbufStruct(), position);
	}
}
