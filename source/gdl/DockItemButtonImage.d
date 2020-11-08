module gdl.DockItemButtonImage;

private import gdl.c.functions;
public  import gdl.c.types;
private import glib.ConstructionException;
private import gobject.ObjectG;
private import gtk.BuildableIF;
private import gtk.BuildableT;
private import gtk.Widget;


/** */
public class DockItemButtonImage : Widget
{
	/** the main Gtk struct */
	protected GdlDockItemButtonImage* gdlDockItemButtonImage;

	/** Get the main Gtk struct */
	public GdlDockItemButtonImage* getDockItemButtonImageStruct(bool transferOwnership = false)
	{
		if (transferOwnership)
			ownedRef = false;
		return gdlDockItemButtonImage;
	}

	/** the main Gtk struct as a void* */
	protected override void* getStruct()
	{
		return cast(void*)gdlDockItemButtonImage;
	}

	/**
	 * Sets our main struct and passes it to the parent class.
	 */
	public this (GdlDockItemButtonImage* gdlDockItemButtonImage, bool ownedRef = false)
	{
		this.gdlDockItemButtonImage = gdlDockItemButtonImage;
		super(cast(GtkWidget*)gdlDockItemButtonImage, ownedRef);
	}


	/** */
	public static GType getType()
	{
		return gdl_dock_item_button_image_get_type();
	}

	/**
	 * Creates a new GDL dock button image object.
	 *
	 * Params:
	 *     imageType = Specifies what type of image the widget should display
	 *
	 * Returns: The newly created dock item button image widget
	 *
	 * Throws: ConstructionException GTK+ fails to create the object.
	 */
	public this(GdlDockItemButtonImageType imageType)
	{
		auto __p = gdl_dock_item_button_image_new(imageType);

		if(__p is null)
		{
			throw new ConstructionException("null returned by new");
		}

		this(cast(GdlDockItemButtonImage*) __p);
	}
}
