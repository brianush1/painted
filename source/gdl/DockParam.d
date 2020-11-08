module gdl.DockParam;

private import gdl.c.functions;
public  import gdl.c.types;


/** */
public class DockParam
{
	/** the main Gtk struct */
	protected GdlDockParam* gdlDockParam;
	protected bool ownedRef;

	/** Get the main Gtk struct */
	public GdlDockParam* getDockParamStruct(bool transferOwnership = false)
	{
		if (transferOwnership)
			ownedRef = false;
		return gdlDockParam;
	}

	/** the main Gtk struct as a void* */
	protected void* getStruct()
	{
		return cast(void*)gdlDockParam;
	}

	/**
	 * Sets our main struct and passes it to the parent class.
	 */
	public this (GdlDockParam* gdlDockParam, bool ownedRef = false)
	{
		this.gdlDockParam = gdlDockParam;
		this.ownedRef = ownedRef;
	}


	/** */
	public static GType getType()
	{
		return gdl_dock_param_get_type();
	}
}
