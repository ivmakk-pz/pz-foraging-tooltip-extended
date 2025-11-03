package zombie.ui;

import java.util.ArrayList;
import java.util.Stack;
import zombie.characters.IsoGameCharacter;
import zombie.core.Core;
import zombie.core.textures.Texture;
import zombie.inventory.InventoryItem;
import zombie.iso.IsoObject;

public final class ObjectTooltip extends UIElement {
    public static float alphaStep = 0.1F;
    public boolean bIsItem = false;
    public InventoryItem Item = null;
    public IsoObject Object;
    float alpha = 0.0F;
    int showDelay = 0;
    float targetAlpha = 0.0F;
    Texture texture;
    public int padLeft = 5;
    public int padTop = 5;
    public int padRight = 5;
    public int padBottom = 5;
    private IsoGameCharacter character;
    private boolean measureOnly;
    private float weightOfStack = 0.0F;
    private static int lineSpacing = 14;
    private static int PAD_LEFT = -1;
    private static int PAD_RIGHT;
    private static int PAD_TOP;
    private static int PAD_BOTTOM;
    private static String fontSize = "Small";
    private static UIFont font = UIFont.Small;
    private static Stack<ObjectTooltip.Layout> freeLayouts = new Stack<>();

    public ObjectTooltip() {
        this.texture = Texture.getSharedTexture("black");
        this.width = 130.0F;
        this.height = 130.0F;
        this.defaultDraw = false;
        lineSpacing = TextManager.instance.getFontFromEnum(font).getLineHeight();
        checkFont();
    }

    public static void checkFont() {
        if (!fontSize.equals(Core.getInstance().getOptionTooltipFont())) {
            fontSize = Core.getInstance().getOptionTooltipFont();
            if ("Large".equals(fontSize)) {
                font = UIFont.Large;
            } else if ("Medium".equals(fontSize)) {
                font = UIFont.Medium;
            } else {
                font = UIFont.Small;
            }

            lineSpacing = TextManager.instance.getFontFromEnum(font).getLineHeight();
        }

        int int0 = TextManager.instance.MeasureStringX(font, "0");
        PAD_RIGHT = int0;
        PAD_LEFT = int0;
        PAD_TOP = PAD_BOTTOM = int0 / 2;
    }

    public UIFont getFont() {
        return font;
    }

    public int getLineSpacing() {
        return lineSpacing;
    }

    @Override
    public void DrawText(UIFont _font, String text, double x, double y, double r, double g, double b, double _alpha) {
        if (!this.measureOnly) {
            super.DrawText(_font, text, x, y, r, g, b, _alpha);
        }
    }

    @Override
    public void DrawTextCentre(UIFont _font, String text, double x, double y, double r, double g, double b, double _alpha) {
        if (!this.measureOnly) {
            super.DrawTextCentre(_font, text, x, y, r, g, b, _alpha);
        }
    }

    @Override
    public void DrawTextRight(UIFont _font, String text, double x, double y, double r, double g, double b, double _alpha) {
        if (!this.measureOnly) {
            super.DrawTextRight(_font, text, x, y, r, g, b, _alpha);
        }
    }

    public void DrawValueRight(int value, int x, int y, boolean highGood) {
        Integer integer = value;
        String string = integer.toString();
        float float0 = 0.3F;
        float float1 = 1.0F;
        float float2 = 0.2F;
        float float3 = 1.0F;
        if (value > 0) {
            string = "+" + string;
        }

        if (value < 0 && highGood || value > 0 && !highGood) {
            float0 = 0.8F;
            float1 = 0.3F;
            float2 = 0.2F;
        }

        this.DrawTextRight(font, string, x, y, float0, float1, float2, float3);
    }

    public void DrawValueRightNoPlus(int value, int x, int y) {
        Integer integer = value;
        String string = integer.toString();
        float float0 = 1.0F;
        float float1 = 1.0F;
        float float2 = 1.0F;
        float float3 = 1.0F;
        this.DrawTextRight(font, string, x, y, float0, float1, float2, float3);
    }

    public void DrawValueRightNoPlus(float value, int x, int y) {
        Float float0 = value;
        float0 = (int)((float0.floatValue() + 0.01) * 10.0) / 10.0F;
        String string = float0.toString();
        float float1 = 1.0F;
        float float2 = 1.0F;
        float float3 = 1.0F;
        float float4 = 1.0F;
        this.DrawTextRight(font, string, x, y, float1, float2, float3, float4);
    }

    @Override
    public void DrawTextureScaled(Texture tex, double x, double y, double width, double height, double _alpha) {
        if (!this.measureOnly) {
            super.DrawTextureScaled(tex, x, y, width, height, _alpha);
        }
    }

    @Override
    public void DrawTextureScaledAspect(Texture tex, double x, double y, double width, double height, double r, double g, double b, double _alpha) {
        if (!this.measureOnly) {
            super.DrawTextureScaledAspect(tex, x, y, width, height, r, g, b, _alpha);
        }
    }

    public void DrawProgressBar(int x, int y, int w, int h, float f, double r, double g, double b, double a) {
        if (!this.measureOnly) {
            if (f < 0.0F) {
                f = 0.0F;
            }

            if (f > 1.0F) {
                f = 1.0F;
            }

            int int0 = (int)Math.floor(w * f);
            this.DrawTextureScaledColor(null, x - 1.0, y - 1.0, w + 2.0, (double)h, 0.25, 0.25, 0.25, 1.0);
            if (f != 0.0F && f != 1.0F) {
                this.DrawTextureScaledColor(null, (double)x + int0, (double)y, (double)w - int0, h - 2.0, 0.5, 0.5, 0.5, 1.0);
            }

            this.DrawTextureScaledColor(null, (double)x, (double)y, (double)int0, h - 2.0, r, g, b, a);
        }
    }

    @Override
    public Boolean onMouseMove(double dx, double dy) {
        this.setX(this.getX() + dx);
        this.setY(this.getY() + dy);
        return Boolean.FALSE;
    }

    @Override
    public void onMouseMoveOutside(double dx, double dy) {
        this.setX(this.getX() + dx);
        this.setY(this.getY() + dy);
    }

    @Override
    public void render() {
        if (this.isVisible()) {
            if (!(this.alpha <= 0.0F)) {
                if (!this.bIsItem && this.Object != null && this.Object.haveSpecialTooltip()) {
                    this.Object.DoSpecialTooltip(this, this.Object.square);
                }

                super.render();
            }
        }
    }

    public void show(IsoObject obj, double x, double y) {
        this.bIsItem = false;
        this.Object = obj;
        this.setX(x);
        this.setY(y);
        this.targetAlpha = 0.5F;
        this.showDelay = 15;
        this.alpha = 0.0F;
    }

    public void hide() {
        this.Object = null;
        this.showDelay = 0;
        this.setVisible(false);
    }

    @Override
    public void update() {
        if (!(this.alpha <= 0.0F) || this.targetAlpha != 0.0F) {
            if (this.showDelay > 0) {
                if (--this.showDelay == 0) {
                    this.setVisible(true);
                }
            } else {
                if (this.alpha < this.targetAlpha) {
                    this.alpha = this.alpha + alphaStep;
                    if (this.alpha > 0.5F) {
                        this.alpha = 0.5F;
                    }
                } else if (this.alpha > this.targetAlpha) {
                    this.alpha = this.alpha - alphaStep;
                    if (this.alpha < this.targetAlpha) {
                        this.alpha = this.targetAlpha;
                    }
                }
            }
        }
    }

    void show(InventoryItem item, int var2, int var3) {
        this.Object = null;
        this.Item = item;
        this.bIsItem = true;
        this.setX(this.getX());
        this.setY(this.getY());
        this.targetAlpha = 0.5F;
        this.showDelay = 15;
        this.alpha = 0.0F;
        this.setVisible(true);
    }

    public void adjustWidth(int textX, String text) {
        int int0 = TextManager.instance.MeasureStringX(font, text);
        if (textX + int0 + this.padRight > this.width) {
            this.setWidth(textX + int0 + this.padRight);
        }
    }

    public ObjectTooltip.Layout beginLayout() {
        this.padLeft = PAD_LEFT;
        this.padRight = PAD_RIGHT;
        this.padTop = PAD_TOP;
        this.padBottom = PAD_BOTTOM;
        ObjectTooltip.Layout layout = null;
        if (freeLayouts.isEmpty()) {
            layout = new ObjectTooltip.Layout();
        } else {
            layout = freeLayouts.pop();
        }

        return layout;
    }

    public void endLayout(ObjectTooltip.Layout layout) {
        while (layout != null) {
            ObjectTooltip.Layout _layout = layout.next;
            layout.free();
            freeLayouts.push(layout);
            layout = _layout;
        }
    }

    public Texture getTexture() {
        return this.texture;
    }

    public void setCharacter(IsoGameCharacter chr) {
        this.character = chr;
    }

    public IsoGameCharacter getCharacter() {
        return this.character;
    }

    public void setMeasureOnly(boolean b) {
        this.measureOnly = b;
    }

    public boolean isMeasureOnly() {
        return this.measureOnly;
    }

    public float getWeightOfStack() {
        return this.weightOfStack;
    }

    public void setWeightOfStack(float weight) {
        this.weightOfStack = weight;
    }

    public static class Layout {
        public ArrayList<ObjectTooltip.LayoutItem> items = new ArrayList<>();
        public int minLabelWidth;
        public int minValueWidth;
        public ObjectTooltip.Layout next;
        public int nextPadY;
        public int offsetY = 0;
        private static Stack<ObjectTooltip.LayoutItem> freeItems = new Stack<>();

        public ObjectTooltip.LayoutItem addItem() {
            ObjectTooltip.LayoutItem layoutItem = null;
            if (freeItems.isEmpty()) {
                layoutItem = new ObjectTooltip.LayoutItem();
            } else {
                layoutItem = freeItems.pop();
            }

            layoutItem.reset();
            this.items.add(layoutItem);
            return layoutItem;
        }

        public void setMinLabelWidth(int minWidth) {
            this.minLabelWidth = minWidth;
        }

        public void setMinValueWidth(int minWidth) {
            this.minValueWidth = minWidth;
        }

        public int render(int left, int top, ObjectTooltip ui) {
            int int0 = this.minLabelWidth;
            int int1 = this.minValueWidth;
            int int2 = this.minValueWidth;
            int int3 = 0;
            int int4 = 0;
            int int5 = Math.max(TextManager.instance.MeasureStringX(ObjectTooltip.font, "W"), 8);
            int int6 = 0;

            for (int int7 = 0; int7 < this.items.size(); int7++) {
                ObjectTooltip.LayoutItem layoutItem0 = this.items.get(int7);
                layoutItem0.calcSizes();
                if (layoutItem0.hasValue) {
                    int0 = Math.max(int0, layoutItem0.labelWidth);
                    int1 = Math.max(int1, layoutItem0.valueWidth);
                    int2 = Math.max(int2, layoutItem0.valueWidthRight);
                    int3 = Math.max(int3, layoutItem0.progressWidth);
                    int6 = Math.max(int6, Math.max(layoutItem0.labelWidth, this.minLabelWidth) + int5);
                    int4 = Math.max(int4, int0 + int5 + Math.max(Math.max(int1, int2), int3));
                } else {
                    if (layoutItem0.couldHaveValue) {
                        int0 = Math.max(int0, layoutItem0.labelWidth);
                    }

                    int4 = Math.max(int4, layoutItem0.labelWidth);
                }
            }

            if (left + int4 + ui.padRight > ui.width) {
                ui.setWidth(left + int4 + ui.padRight);
            }

            for (int int8 = 0; int8 < this.items.size(); int8++) {
                ObjectTooltip.LayoutItem layoutItem1 = this.items.get(int8);
                layoutItem1.render(left, top, int6, int2, ui);
                top += layoutItem1.height;
            }

            return this.next != null ? this.next.render(left, top + this.next.nextPadY, ui) : top;
        }

        public void free() {
            freeItems.addAll(this.items);
            this.items.clear();
            this.minLabelWidth = 0;
            this.minValueWidth = 0;
            this.next = null;
            this.nextPadY = 0;
            this.offsetY = 0;
        }
    }

    public static class LayoutItem {
        public String label;
        public float r0;
        public float g0;
        public float b0;
        public float a0;
        public boolean hasValue = false;
        public boolean couldHaveValue = false;
        public String value;
        public boolean rightJustify = false;
        public float r1;
        public float g1;
        public float b1;
        public float a1;
        public float progressFraction = -1.0F;
        public int labelWidth;
        public int valueWidth;
        public int valueWidthRight;
        public int progressWidth;
        public int height;

        public void reset() {
            this.label = null;
            this.value = null;
            this.hasValue = false;
            this.couldHaveValue = false;
            this.rightJustify = false;
            this.progressFraction = -1.0F;
        }

        public void setLabel(String _label, float r, float g, float b, float a) {
            this.label = _label;
            this.r0 = r;
            this.b0 = b;
            this.g0 = g;
            this.a0 = a;
        }

        public void setValue(String _label, float r, float g, float b, float a) {
            this.value = _label;
            this.r1 = r;
            this.b1 = b;
            this.g1 = g;
            this.a1 = a;
            this.hasValue = true;
            this.rightJustify = true;
        }

        public void setValueRight(int _value, boolean highGood) {
            this.value = Integer.toString(_value);
            if (_value > 0) {
                this.value = "+" + this.value;
            }

            if ((_value >= 0 || !highGood) && (_value <= 0 || highGood)) {
                this.r1 = Core.getInstance().getGoodHighlitedColor().getR();
                this.g1 = Core.getInstance().getGoodHighlitedColor().getG();
                this.b1 = Core.getInstance().getGoodHighlitedColor().getB();
            } else {
                this.r1 = Core.getInstance().getBadHighlitedColor().getR();
                this.g1 = Core.getInstance().getBadHighlitedColor().getG();
                this.b1 = Core.getInstance().getBadHighlitedColor().getB();
            }

            this.a1 = 1.0F;
            this.hasValue = true;
            this.rightJustify = true;
        }

        public void setValueRightNoPlus(float _value) {
            _value = (int)((_value + 0.005F) * 100.0F) / 100.0F;
            this.value = Float.toString(_value);
            this.r1 = 1.0F;
            this.g1 = 1.0F;
            this.b1 = 1.0F;
            this.a1 = 1.0F;
            this.hasValue = true;
            this.rightJustify = true;
        }

        public void setValueRightNoPlus(int _value) {
            this.value = Integer.toString(_value);
            this.r1 = 1.0F;
            this.g1 = 1.0F;
            this.b1 = 1.0F;
            this.a1 = 1.0F;
            this.hasValue = true;
            this.rightJustify = true;
        }

        public void setProgress(float fraction, float r, float g, float b, float a) {
            this.progressFraction = fraction;
            this.r1 = r;
            this.b1 = b;
            this.g1 = g;
            this.a1 = a;
            this.hasValue = true;
        }

        public void calcSizes() {
            this.labelWidth = this.valueWidth = this.valueWidthRight = this.progressWidth = 0;
            if (this.label != null) {
                this.labelWidth = TextManager.instance.MeasureStringX(ObjectTooltip.font, this.label);
            }

            if (this.hasValue) {
                if (this.value != null) {
                    int int0 = TextManager.instance.MeasureStringX(ObjectTooltip.font, this.value);
                    this.valueWidth = this.rightJustify ? 0 : int0;
                    this.valueWidthRight = this.rightJustify ? int0 : 0;
                } else if (this.progressFraction != -1.0F) {
                    this.progressWidth = 80;
                }
            }

            int int1 = 1;
            if (this.label != null) {
                int int2 = 1;

                for (int int3 = 0; int3 < this.label.length(); int3++) {
                    if (this.label.charAt(int3) == '\n') {
                        int2++;
                    }
                }

                int1 = Math.max(int1, int2);
            }

            if (this.hasValue && this.value != null) {
                int int4 = 1;

                for (int int5 = 0; int5 < this.value.length(); int5++) {
                    if (this.value.charAt(int5) == '\n') {
                        int4++;
                    }
                }

                int1 = Math.max(int1, int4);
            }

            this.height = int1 * ObjectTooltip.lineSpacing;
        }

        public void render(int x, int y, int mid, int right, ObjectTooltip ui) {
            if (this.label != null) {
                ui.DrawText(ObjectTooltip.font, this.label, x, y, this.r0, this.g0, this.b0, this.a0);
            }

            if (this.value != null) {
                if (this.rightJustify) {
                    ui.DrawTextRight(ObjectTooltip.font, this.value, x + mid + right, y, this.r1, this.g1, this.b1, this.a1);
                } else {
                    ui.DrawText(ObjectTooltip.font, this.value, x + mid, y, this.r1, this.g1, this.b1, this.a1);
                }
            }

            if (this.progressFraction != -1.0F) {
                byte byte0 = 5;
                if ("Medium".equals(ObjectTooltip.fontSize)) {
                    byte0 = 6;
                }

                if ("Large".equals(ObjectTooltip.fontSize)) {
                    byte0 = 7;
                }

                ui.DrawProgressBar(x + mid, y + ObjectTooltip.lineSpacing / 2 - 1, right, byte0, this.progressFraction, this.r1, this.g1, this.b1, this.a1);
            }
        }
    }
}
