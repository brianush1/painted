module gdl.DockItemClass;

private import gdl.c.functions;
public  import gdl.c.types;


/** */
public class DockItemClass
{
	/** the main Gtk struct */
	protected GdlDockItemClass* gdlDockItemClass;
	protected bool ownedRef;

	/** Get the main Gtk struct */
	public GdlDockItemClass* getDockItemClassStruct(bool transferOwnership = false)
	{
		if (transferOwnership)
			ownedRef = false;
		return gdlDockItemClass;
	}

	/** the main Gtk struct as a void* */
	protected void* getStruct()
	{
		return cast(void*)gdlDockItemClass;
	}

	/**
	 * Sets our main struct and passes it to the parent class.
	 */
	public this (GdlDockItemClass* gdlDockItemClass, bool ownedRef = false)
	{
		this.gdlDockItemClass = gdlDockItemClass;
		this.ownedRef = ownedRef;
	}


	/**
	 * Define in the corresponding kind of dock item has a grip. Even if an item
	 * has a grip it can be hidden.
	 *
	 * Params:
	 *     hasGrip = %TRUE is the dock item has a grip
	 *
	 * Since: 3.6
	 */
	public void setHasGrip(bool hasGrip)
	{
		gdl_dock_item_class_set_has_grip(gdlDockItemClass, hasGrip);
	}
}
