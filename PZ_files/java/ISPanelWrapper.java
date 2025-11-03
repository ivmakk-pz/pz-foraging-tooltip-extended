package zombie.ui.ISUIWrapper;

import se.krka.kahlua.vm.KahluaTable;
import zombie.Lua.LuaManager;

public class ISPanelWrapper extends ISUIElementWrapper {
    public ISPanelWrapper(KahluaTable table) {
        super(table);
    }

    public ISPanelWrapper(double double0, double double1, double double2, double double3) {
        super(double0, double1, double2, double3);
        KahluaTable table = (KahluaTable)LuaManager.env.rawget("ISPanel");
        this.table.setMetatable(table);
        table.rawset("__index", table);
        this.table.rawset("x", double0);
        this.table.rawset("y", double1);
        this.table.rawset("background", true);
        this.table.rawset("backgroundColor", this.setRGBA(LuaManager.platform.newTable(), 0.0, 0.0, 0.0, 0.5));
        this.table.rawset("borderColor", this.setRGBA(LuaManager.platform.newTable(), 0.4, 0.4, 0.4, 1.0));
        this.table.rawset("width", double2);
        this.table.rawset("height", double3);
        this.table.rawset("anchorLeft", true);
        this.table.rawset("anchorRight", false);
        this.table.rawset("anchorTop", true);
        this.table.rawset("anchorBottom", false);
        this.table.rawset("moveWithMouse", false);
    }

    public void noBackground() {
        this.table.rawset("background", false);
    }
}
