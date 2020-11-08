module gdl.c.functions;

import std.stdio;
import gdl.c.types;
version (Windows)
	static immutable LIBRARY_GDL = ["libgdl-3-5.dll;gdl-3-3.5.dll;gdl-3.dll"];
else version (OSX)
	static immutable LIBRARY_GDL = ["libgdl-3.5.dylib"];
else
	static immutable LIBRARY_GDL = ["libgdl-3.so.5"];

__gshared extern(C)
{

	// gdl.Dock

	GType gdl_dock_get_type();
	GtkWidget* gdl_dock_new();
	void gdl_dock_add_floating_item(GdlDock* dock, GdlDockItem* item, int x, int y, int width, int height);
	void gdl_dock_add_item(GdlDock* dock, GdlDockItem* item, GdlDockPlacement placement);
	GdlDockItem* gdl_dock_get_item_by_name(GdlDock* dock, const(char)* name);
	GList* gdl_dock_get_named_items(GdlDock* dock);
	GdlDockPlaceholder* gdl_dock_get_placeholder_by_name(GdlDock* dock, const(char)* name);
	GdlDockObject* gdl_dock_get_root(GdlDock* dock);
	void gdl_dock_hide_preview(GdlDock* dock);
	GtkWidget* gdl_dock_new_from(GdlDock* original, int floating);
	void gdl_dock_set_skip_taskbar(GdlDock* dock, int skip);
	void gdl_dock_show_preview(GdlDock* dock, GdkRectangle* rect);
	void gdl_dock_xor_rect(GdlDock* dock, GdkRectangle* rect);
	void gdl_dock_xor_rect_hide(GdlDock* dock);

	// gdl.DockBar

	GType gdl_dock_bar_get_type();
	GtkWidget* gdl_dock_bar_new(GObject* master);
	GtkOrientation gdl_dock_bar_get_orientation(GdlDockBar* dockbar);
	GdlDockBarStyle gdl_dock_bar_get_style(GdlDockBar* dockbar);
	void gdl_dock_bar_set_orientation(GdlDockBar* dockbar, GtkOrientation orientation);
	void gdl_dock_bar_set_style(GdlDockBar* dockbar, GdlDockBarStyle style);

	// gdl.DockItem

	GType gdl_dock_item_get_type();
	GtkWidget* gdl_dock_item_new(const(char)* name, const(char)* longName, GdlDockItemBehavior behavior);
	GtkWidget* gdl_dock_item_new_with_pixbuf_icon(const(char)* name, const(char)* longName, GdkPixbuf* pixbufIcon, GdlDockItemBehavior behavior);
	GtkWidget* gdl_dock_item_new_with_stock(const(char)* name, const(char)* longName, const(char)* stockId, GdlDockItemBehavior behavior);
	void gdl_dock_item_bind(GdlDockItem* item, GtkWidget* dock);
	void gdl_dock_item_dock_to(GdlDockItem* item, GdlDockItem* target, GdlDockPlacement position, int dockingParam);
	GdlDockItemBehavior gdl_dock_item_get_behavior_flags(GdlDockItem* item);
	GtkWidget* gdl_dock_item_get_child(GdlDockItem* item);
	void gdl_dock_item_get_drag_area(GdlDockItem* item, GdkRectangle* rect);
	GtkWidget* gdl_dock_item_get_grip(GdlDockItem* item);
	GtkOrientation gdl_dock_item_get_orientation(GdlDockItem* item);
	GtkWidget* gdl_dock_item_get_tablabel(GdlDockItem* item);
	void gdl_dock_item_hide_grip(GdlDockItem* item);
	void gdl_dock_item_hide_item(GdlDockItem* item);
	void gdl_dock_item_iconify_item(GdlDockItem* item);
	int gdl_dock_item_is_closed(GdlDockItem* item);
	int gdl_dock_item_is_iconified(GdlDockItem* item);
	int gdl_dock_item_is_placeholder(GdlDockItem* item);
	void gdl_dock_item_lock(GdlDockItem* item);
	void gdl_dock_item_notify_deselected(GdlDockItem* item);
	void gdl_dock_item_notify_selected(GdlDockItem* item);
	int gdl_dock_item_or_child_has_focus(GdlDockItem* item);
	void gdl_dock_item_preferred_size(GdlDockItem* item, GtkRequisition* req);
	void gdl_dock_item_set_behavior_flags(GdlDockItem* item, GdlDockItemBehavior behavior, int clear);
	void gdl_dock_item_set_child(GdlDockItem* item, GtkWidget* child);
	void gdl_dock_item_set_default_position(GdlDockItem* item, GdlDockObject* reference);
	void gdl_dock_item_set_orientation(GdlDockItem* item, GtkOrientation orientation);
	void gdl_dock_item_set_tablabel(GdlDockItem* item, GtkWidget* tablabel);
	void gdl_dock_item_show_grip(GdlDockItem* item);
	void gdl_dock_item_show_item(GdlDockItem* item);
	void gdl_dock_item_unbind(GdlDockItem* item);
	void gdl_dock_item_unlock(GdlDockItem* item);
	void gdl_dock_item_unset_behavior_flags(GdlDockItem* item, GdlDockItemBehavior behavior);

	// gdl.DockItemButtonImage

	GType gdl_dock_item_button_image_get_type();
	GtkWidget* gdl_dock_item_button_image_new(GdlDockItemButtonImageType imageType);

	// gdl.DockItemClass

	void gdl_dock_item_class_set_has_grip(GdlDockItemClass* itemClass, int hasGrip);

	// gdl.DockItemGrip

	GType gdl_dock_item_grip_get_type();
	GtkWidget* gdl_dock_item_grip_new(GdlDockItem* item);
	int gdl_dock_item_grip_has_event(GdlDockItemGrip* grip, GdkEvent* event);
	void gdl_dock_item_grip_hide_handle(GdlDockItemGrip* grip);
	void gdl_dock_item_grip_set_cursor(GdlDockItemGrip* grip, int inDrag);
	void gdl_dock_item_grip_set_label(GdlDockItemGrip* grip, GtkWidget* label);
	void gdl_dock_item_grip_show_handle(GdlDockItemGrip* grip);

	// gdl.DockLayout

	GType gdl_dock_layout_get_type();
	GdlDockLayout* gdl_dock_layout_new(GObject* master);
	void gdl_dock_layout_attach(GdlDockLayout* layout, GdlDockMaster* master);
	void gdl_dock_layout_delete_layout(GdlDockLayout* layout, const(char)* name);
	GList* gdl_dock_layout_get_layouts(GdlDockLayout* layout, int includeDefault);
	GObject* gdl_dock_layout_get_master(GdlDockLayout* layout);
	int gdl_dock_layout_is_dirty(GdlDockLayout* layout);
	int gdl_dock_layout_load_from_file(GdlDockLayout* layout, const(char)* filename);
	int gdl_dock_layout_load_layout(GdlDockLayout* layout, const(char)* name);
	void gdl_dock_layout_save_layout(GdlDockLayout* layout, const(char)* name);
	int gdl_dock_layout_save_to_file(GdlDockLayout* layout, const(char)* filename);
	void gdl_dock_layout_set_master(GdlDockLayout* layout, GObject* master);

	// gdl.DockMaster

	GType gdl_dock_master_get_type();
	void gdl_dock_master_add(GdlDockMaster* master, GdlDockObject* object);
	void gdl_dock_master_foreach(GdlDockMaster* master, GFunc function_, void* userData);
	void gdl_dock_master_foreach_toplevel(GdlDockMaster* master, int includeController, GFunc function_, void* userData);
	GdlDockObject* gdl_dock_master_get_controller(GdlDockMaster* master);
	char* gdl_dock_master_get_dock_name(GdlDockMaster* master);
	GdlDockObject* gdl_dock_master_get_object(GdlDockMaster* master, const(char)* nickName);
	void gdl_dock_master_remove(GdlDockMaster* master, GdlDockObject* object);
	void gdl_dock_master_set_controller(GdlDockMaster* master, GdlDockObject* newController);

	// gdl.DockNotebook

	GType gdl_dock_notebook_get_type();
	GtkWidget* gdl_dock_notebook_new();

	// gdl.DockObject

	GType gdl_dock_object_get_type();
	const(char)* gdl_dock_object_nick_from_type(GType type);
	GType gdl_dock_object_set_type_for_nick(const(char)* nick, GType type);
	GType gdl_dock_object_type_from_nick(const(char)* nick);
	void gdl_dock_object_bind(GdlDockObject* object, GObject* master);
	int gdl_dock_object_child_placement(GdlDockObject* object, GdlDockObject* child, GdlDockPlacement* placement);
	void gdl_dock_object_detach(GdlDockObject* object, int recursive);
	void gdl_dock_object_dock(GdlDockObject* object, GdlDockObject* requestor, GdlDockPlacement position, GValue* otherData);
	int gdl_dock_object_dock_request(GdlDockObject* object, int x, int y, GdlDockRequest* request);
	void gdl_dock_object_freeze(GdlDockObject* object);
	GdlDockObject* gdl_dock_object_get_controller(GdlDockObject* object);
	const(char)* gdl_dock_object_get_long_name(GdlDockObject* object);
	GObject* gdl_dock_object_get_master(GdlDockObject* object);
	const(char)* gdl_dock_object_get_name(GdlDockObject* object);
	GdlDockObject* gdl_dock_object_get_parent_object(GdlDockObject* object);
	GdkPixbuf* gdl_dock_object_get_pixbuf(GdlDockObject* object);
	const(char)* gdl_dock_object_get_stock_id(GdlDockObject* object);
	GdlDock* gdl_dock_object_get_toplevel(GdlDockObject* object);
	int gdl_dock_object_is_automatic(GdlDockObject* object);
	int gdl_dock_object_is_bound(GdlDockObject* object);
	int gdl_dock_object_is_closed(GdlDockObject* object);
	int gdl_dock_object_is_compound(GdlDockObject* object);
	int gdl_dock_object_is_frozen(GdlDockObject* object);
	void gdl_dock_object_layout_changed_notify(GdlDockObject* object);
	void gdl_dock_object_present(GdlDockObject* object, GdlDockObject* child);
	void gdl_dock_object_reduce(GdlDockObject* object);
	int gdl_dock_object_reorder(GdlDockObject* object, GdlDockObject* child, GdlDockPlacement newPosition, GValue* otherData);
	void gdl_dock_object_set_long_name(GdlDockObject* object, const(char)* name);
	void gdl_dock_object_set_manual(GdlDockObject* object);
	void gdl_dock_object_set_name(GdlDockObject* object, const(char)* name);
	void gdl_dock_object_set_pixbuf(GdlDockObject* object, GdkPixbuf* icon);
	void gdl_dock_object_set_stock_id(GdlDockObject* object, const(char)* stockId);
	void gdl_dock_object_thaw(GdlDockObject* object);
	void gdl_dock_object_unbind(GdlDockObject* object);

	// gdl.DockPaned

	GType gdl_dock_paned_get_type();
	GtkWidget* gdl_dock_paned_new(GtkOrientation orientation);

	// gdl.DockParam

	GType gdl_dock_param_get_type();

	// gdl.DockPlaceholder

	GType gdl_dock_placeholder_get_type();
	GtkWidget* gdl_dock_placeholder_new(const(char)* name, GdlDockObject* object, GdlDockPlacement position, int sticky);
	void gdl_dock_placeholder_attach(GdlDockPlaceholder* ph, GdlDockObject* object);

	// gdl.DockTablabel

	GType gdl_dock_tablabel_get_type();
	GtkWidget* gdl_dock_tablabel_new(GdlDockItem* item);
	void gdl_dock_tablabel_activate(GdlDockTablabel* tablabel);
	void gdl_dock_tablabel_deactivate(GdlDockTablabel* tablabel);

	// gdl.PreviewWindow

	GType gdl_preview_window_get_type();
	GtkWidget* gdl_preview_window_new();
	void gdl_preview_window_update(GdlPreviewWindow* window, GdkRectangle* rect);

	// gdl.Switcher

	GType gdl_switcher_get_type();
	GtkWidget* gdl_switcher_new();
	int gdl_switcher_insert_page(GdlSwitcher* switcher, GtkWidget* page, GtkWidget* tabWidget, const(char)* label, const(char)* tooltips, const(char)* stockId, GdkPixbuf* pixbufIcon, int position);
}