package zombie.ui.ISUIWrapper;

import se.krka.kahlua.vm.KahluaTable;
import zombie.Lua.LuaManager;

public class ISToolTipWrapper extends ISPanelWrapper {
    public ISToolTipWrapper(KahluaTable table) {
        super(table);
    }

    public ISToolTipWrapper() {
        super(0.0, 0.0, 0.0, 0.0);
        KahluaTable table0 = (KahluaTable)LuaManager.env.rawget("ISToolTip");
        this.table.setMetatable(table0);
        table0.rawset("__index", table0);
        this.noBackground();
        this.table.rawset("name", null);
        this.table.rawset("description", "");
        this.table.rawset("borderColor", this.setRGBA(LuaManager.platform.newTable(), 0.4, 0.4, 0.4, 1.0));
        this.table.rawset("backgroundColor", this.setRGBA(LuaManager.platform.newTable(), 0.0, 0.0, 0.0, 0.0));
        this.table.rawset("width", 0.0);
        this.table.rawset("height", 0.0);
        this.table.rawset("anchorLeft", true);
        this.table.rawset("anchorRight", false);
        this.table.rawset("anchorTop", true);
        this.table.rawset("anchorBottom", false);
        KahluaTable table1 = (KahluaTable)LuaHelpers.callLuaClass("ISRichTextPanel", "new", null, 0.0, 0.0, 0.0, 0.0);
        ISPanelWrapper iSPanelWrapper = new ISPanelWrapper(table1);
        this.table.rawset("descriptionPanel", table1);
        table1.rawset("marginLeft", 0.0);
        table1.rawset("marginRight", 0.0);
        iSPanelWrapper.initialise();
        iSPanelWrapper.instantiate();
        iSPanelWrapper.noBackground();
        table1.rawset("backgroundColor", this.setRGBA(LuaManager.platform.newTable(), 0.0, 0.0, 0.0, 0.3));
        table1.rawset("borderColor", this.setRGBA(LuaManager.platform.newTable(), 1.0, 1.0, 1.0, 0.1));
        this.table.rawset("owner", null);
        this.table.rawset("followMouse", true);
        this.table.rawset("nameMarginX", 50.0);
        this.table.rawset("defaultMyWidth", 220.0);
    }

    public void setName(String string) {
        this.table.rawset("name", string);
    }

    public void reset() {
        this.setVisible(false);
        this.noBackground();
        this.table.rawset("name", null);
        this.table.rawset("description", "");
        this.table.rawset("texture", null);
        this.table.rawset("footNote", null);
        this.setRGBA((KahluaTable)this.table.rawget("borderColor"), 0.4, 0.4, 0.4, 1.0);
        this.setRGBA((KahluaTable)this.table.rawget("backgroundColor"), 0.0, 0.0, 0.0, 0.0);
        this.table.rawset("width", 0.0);
        this.table.rawset("height", 0.0);
        this.table.rawset("maxLineWidth", null);
        this.table.rawset("desiredX", null);
        this.table.rawset("desiredY", null);
        this.table.rawset("anchorLeft", true);
        this.table.rawset("anchorRight", false);
        this.table.rawset("anchorTop", true);
        this.table.rawset("anchorBottom", false);
        KahluaTable table = (KahluaTable)this.table.rawget("descriptionPanel");
        table.rawset("marginLeft", 0.0);
        table.rawset("marginRight", 0.0);
        this.setRGBA((KahluaTable)table.rawget("backgroundColor"), 0.0, 0.0, 0.0, 0.3);
        this.setRGBA((KahluaTable)table.rawget("borderColor"), 1.0, 1.0, 1.0, 0.1);
        this.table.rawset("owner", null);
        this.table.rawset("contextMenu", null);
        this.table.rawset("followMouse", true);
    }
}
