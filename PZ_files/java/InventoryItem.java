package zombie.inventory;

import java.io.DataInputStream;
import java.io.File;
import java.io.IOException;
import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Objects;
import se.krka.kahlua.vm.KahluaTable;
import se.krka.kahlua.vm.KahluaTableIterator;
import zombie.GameTime;
import zombie.GameWindow;
import zombie.SandboxOptions;
import zombie.Lua.LuaEventManager;
import zombie.Lua.LuaManager;
import zombie.audio.BaseSoundEmitter;
import zombie.characterTextures.BloodBodyPartType;
import zombie.characterTextures.BloodClothingType;
import zombie.characters.BaseCharacterSoundEmitter;
import zombie.characters.IsoGameCharacter;
import zombie.characters.IsoPlayer;
import zombie.characters.IsoZombie;
import zombie.characters.SurvivorDesc;
import zombie.characters.UnderwearDefinition;
import zombie.characters.ZombiesZoneDefinition;
import zombie.characters.animals.AnimalDefinitions;
import zombie.characters.animals.AnimalTracks;
import zombie.characters.animals.IsoAnimal;
import zombie.characters.animals.datas.AnimalBreed;
import zombie.characters.skills.PerkFactory;
import zombie.core.Color;
import zombie.core.Colors;
import zombie.core.Core;
import zombie.core.Translator;
import zombie.core.logger.ExceptionLogger;
import zombie.core.math.PZMath;
import zombie.core.random.Rand;
import zombie.core.skinnedmodel.model.WorldItemAtlas;
import zombie.core.skinnedmodel.population.ClothingItem;
import zombie.core.skinnedmodel.population.Outfit;
import zombie.core.skinnedmodel.visual.ItemVisual;
import zombie.core.stash.StashSystem;
import zombie.core.textures.ColorInfo;
import zombie.core.textures.Texture;
import zombie.core.utils.Bits;
import zombie.debug.DebugLog;
import zombie.debug.DebugOptions;
import zombie.entity.ComponentType;
import zombie.entity.GameEntity;
import zombie.entity.GameEntityFactory;
import zombie.entity.GameEntityType;
import zombie.entity.components.attributes.Attribute;
import zombie.entity.components.fluids.Fluid;
import zombie.entity.components.fluids.FluidContainer;
import zombie.inventory.types.AnimalInventoryItem;
import zombie.inventory.types.Clothing;
import zombie.inventory.types.Drainable;
import zombie.inventory.types.DrainableComboItem;
import zombie.inventory.types.Food;
import zombie.inventory.types.HandWeapon;
import zombie.inventory.types.InventoryContainer;
import zombie.inventory.types.Key;
import zombie.inventory.types.WeaponType;
import zombie.iso.IsoDirections;
import zombie.iso.IsoGridSquare;
import zombie.iso.IsoObject;
import zombie.iso.IsoWorld;
import zombie.iso.objects.IsoDeadBody;
import zombie.iso.objects.IsoFireManager;
import zombie.iso.objects.IsoFireplace;
import zombie.iso.objects.IsoWorldInventoryObject;
import zombie.iso.objects.RainManager;
import zombie.network.GameClient;
import zombie.network.GameServer;
import zombie.network.PacketTypes;
import zombie.network.packets.INetworkPacket;
import zombie.radio.ZomboidRadio;
import zombie.radio.media.MediaData;
import zombie.scripting.ScriptManager;
import zombie.scripting.objects.Item;
import zombie.scripting.objects.ItemKey;
import zombie.scripting.objects.ItemReplacement;
import zombie.scripting.objects.ItemTag;
import zombie.scripting.objects.ModelKey;
import zombie.scripting.objects.WeaponCategory;
import zombie.ui.ObjectTooltip;
import zombie.ui.TextManager;
import zombie.ui.UIFont;
import zombie.util.StringUtils;
import zombie.util.Type;
import zombie.util.io.BitHeader;
import zombie.util.io.BitHeaderRead;
import zombie.util.io.BitHeaderWrite;
import zombie.util.list.PZArrayUtil;
import zombie.vehicles.VehiclePart;
import zombie.world.ItemInfo;
import zombie.world.WorldDictionary;

public class InventoryItem extends GameEntity {
    private static final ByteBuffer tempBuffer = ByteBuffer.allocate(20000);
    protected static final int DEFAULT_USES = 1;
    protected IsoGameCharacter previousOwner = null;
    protected Item ScriptItem = null;
    protected ItemType cat = ItemType.None;
    protected ItemContainer container;
    protected int containerX = 0;
    protected int containerY = 0;
    protected String name;
    protected String replaceOnUse = null;
    protected String replaceOnUseFullType = null;
    protected int ConditionMax = 10;
    protected ItemContainer rightClickContainer = null;
    protected Texture texture;
    protected Texture texturerotten;
    protected Texture textureCooked;
    protected Texture textureBurnt;
    protected String type;
    protected String fullType;
    protected int uses = 1;
    protected float Age = 0.0F;
    protected float LastAged = -1.0F;
    protected boolean IsCookable = false;
    protected float CookingTime = 0.0F;
    protected float MinutesToCook = 60.0F;
    protected float MinutesToBurn = 120.0F;
    public boolean Cooked = false;
    protected boolean Burnt = false;
    protected int OffAge = 1000000000;
    protected int OffAgeMax = 1000000000;
    protected float Weight = 1.0F;
    protected float ActualWeight = 1.0F;
    protected String WorldTexture;
    protected String Description;
    protected int Condition = 10;
    protected String OffString = Translator.getText("Tooltip_food_Rotten");
    protected String FreshString = Translator.getText("Tooltip_food_Fresh");
    protected String StaleString = Translator.getText("Tooltip_food_Stale");
    protected String CookedString = Translator.getText("Tooltip_food_Cooked");
    protected String ToastedString = Translator.getText("Tooltip_food_Toasted");
    protected String GrilledString = Translator.getText("Tooltip_food_Grilled");
    protected String UnCookedString = Translator.getText("Tooltip_food_Uncooked");
    protected String FrozenString = Translator.getText("Tooltip_food_Frozen");
    protected String BurntString = Translator.getText("Tooltip_food_Burnt");
    protected String EmptyString = Translator.getText("ContextMenu_Empty");
    private final String brokenString = Translator.getText("Tooltip_broken");
    private final String bluntString = Translator.getText("Tooltip_blunt");
    private final String dullString = Translator.getText("Tooltip_dull");
    private final String wornString = Translator.getText("IGUI_ClothingName_Worn");
    private final String bloodyString = Translator.getText("IGUI_ClothingName_Bloody");
    protected String module = "Base";
    protected float boredomChange = 0.0F;
    protected float unhappyChange = 0.0F;
    protected float stressChange = 0.0F;
    protected ArrayList<IsoObject> Taken = new ArrayList<>();
    protected IsoDirections placeDir = IsoDirections.Max;
    protected IsoDirections newPlaceDir = IsoDirections.Max;
    private KahluaTable table = null;
    public String ReplaceOnUseOn = null;
    public Color col = Color.white;
    public boolean CanStack = false;
    private boolean activated = false;
    private boolean isTorchCone = false;
    private int lightDistance = 0;
    private int Count = 1;
    public float fatigueChange = 0.0F;
    public IsoWorldInventoryObject worldItem = null;
    public IsoDeadBody deadBodyObject = null;
    private String customMenuOption = null;
    private String tooltip = null;
    private String displayCategory = null;
    private int haveBeenRepaired = 0;
    private boolean broken = false;
    private String originalName = null;
    public int id = 0;
    public boolean RequiresEquippedBothHands;
    public ByteBuffer byteData;
    public ArrayList<String> extraItems = new ArrayList<>();
    private boolean customName = false;
    private String breakSound = null;
    protected boolean alcoholic = false;
    private float alcoholPower = 0.0F;
    private float bandagePower = 0.0F;
    private float ReduceInfectionPower = 0.0F;
    private boolean customWeight = false;
    private boolean customColor = false;
    private int keyId = -1;
    private boolean remoteController = false;
    private boolean canBeRemote = false;
    private int remoteControlID = -1;
    private int remoteRange = 0;
    private float colorRed = 1.0F;
    private float colorGreen = 1.0F;
    private float colorBlue = 1.0F;
    private String countDownSound = null;
    private String explosionSound = null;
    private IsoGameCharacter equipParent = null;
    private String evolvedRecipeName = null;
    private float metalValue = 0.0F;
    private float itemHeat = 1.0F;
    private float meltingTime = 0.0F;
    private String worker;
    private boolean isWet = false;
    private float wetCooldown = -1.0F;
    private String itemWhenDry = null;
    private boolean favorite = false;
    protected ArrayList<String> requireInHandOrInventory = null;
    private String stashMap = null;
    private boolean zombieInfected = false;
    private float itemCapacity = -1.0F;
    private int maxCapacity = -1;
    private float brakeForce = 0.0F;
    private float durability = 0.0F;
    private int chanceToSpawnDamaged = 0;
    private float conditionLowerNormal = 0.0F;
    private float conditionLowerOffroad = 0.0F;
    private float wheelFriction = 0.0F;
    private float suspensionDamping = 0.0F;
    private float suspensionCompression = 0.0F;
    private float engineLoudness = 0.0F;
    protected ItemVisual visual = null;
    protected String staticModel = null;
    private ArrayList<String> iconsForTexture = null;
    private ArrayList<BloodClothingType> bloodClothingType = new ArrayList<>();
    private int stashChance = 80;
    private String ammoType = null;
    private int maxAmmo = 0;
    private int currentAmmoCount = 0;
    private String gunType = null;
    private String attachmentType = null;
    private ArrayList<String> attachmentsProvided = null;
    private int attachedSlot = -1;
    private String attachedSlotType = null;
    private String attachmentReplacement = null;
    private String attachedToModel = null;
    private final String m_alternateModelName = null;
    private short registry_id = -1;
    public float worldScale = 1.0F;
    public float worldXRotation = 0.0F;
    public float worldYRotation = 0.0F;
    public float worldZRotation = -1.0F;
    public float worldAlpha = 1.0F;
    private short recordedMediaIndex = -1;
    private byte mediaType = -1;
    private boolean isInitialised = false;
    public WorldItemAtlas.ItemTexture atlasTexture = null;
    protected Texture textureColorMask;
    protected Texture textureFluidMask;
    private AnimalTracks animalTracks;
    private ArrayList<String> staticModelsByIndex = null;
    private ArrayList<String> worldStaticModelsByIndex = null;
    private boolean bDoingExtendedPlacement = false;
    private int modelIndex = -1;
    private final int maxTextLength = 256;
    private IsoPlayer equippedAndActivatedPlayer = null;
    private long equippedAndActivatedSound = 0L;
    private boolean isCraftingConsumed = false;
    public float jobDelta = 0.0F;
    public String jobType = null;
    public String mainCategory = null;
    private boolean canBeActivated;
    private float lightStrength;
    public String CloseKillMove = null;
    private boolean beingFilled = false;

    public int getSaveType() {
        throw new RuntimeException("InventoryItem.getSaveType() not implemented for " + this.getClass().getName());
    }

    public IsoWorldInventoryObject getWorldItem() {
        return this.worldItem;
    }

    public void setEquipParent(IsoGameCharacter parent) {
        this.setEquipParent(parent, true);
    }

    public void setEquipParent(IsoGameCharacter character, boolean boolean0) {
        this.equipParent = character;
        if (this.equipParent == null) {
            this.onUnEquip();
        } else {
            this.onEquip(boolean0);
        }
    }

    public IsoGameCharacter getEquipParent() {
        return this.equipParent == null || this.equipParent.getPrimaryHandItem() != this && this.equipParent.getSecondaryHandItem() != this
            ? null
            : this.equipParent;
    }

    public String getBringToBearSound() {
        return this.getScriptItem().getBringToBearSound();
    }

    public String getAimReleaseSound() {
        return this.getScriptItem().getAimReleaseSound();
    }

    public String getEquipSound() {
        return this.getScriptItem().getEquipSound();
    }

    public String getUnequipSound() {
        return this.getScriptItem().getUnequipSound();
    }

    public String getDropSound() {
        if (StringUtils.equalsIgnoreCase(this.getType(), "CorpseAnimal")) {
            IsoDeadBody deadBody = this.loadCorpseFromByteData(null);
            if (deadBody != null && deadBody.isAnimal()) {
                AnimalDefinitions animalDefinitions = AnimalDefinitions.getDef(deadBody.getAnimalType());
                if (animalDefinitions == null) {
                    return this.getScriptItem().getDropSound();
                } else {
                    AnimalBreed animalBreed = animalDefinitions.getBreedByName(deadBody.getBreed());
                    if (animalBreed == null) {
                        return this.getScriptItem().getDropSound();
                    } else {
                        AnimalBreed.Sound sound = animalBreed.getSound("put_down_corpse");
                        return sound == null ? this.getScriptItem().getDropSound() : sound.soundName;
                    }
                }
            } else {
                return this.getScriptItem().getDropSound();
            }
        } else {
            return this.getScriptItem().getDropSound();
        }
    }

    public void setWorldItem(IsoWorldInventoryObject w) {
        this.worldItem = w;
    }

    public void setJobDelta(float delta) {
        this.jobDelta = delta;
    }

    public float getJobDelta() {
        return this.jobDelta;
    }

    public void setJobType(String _type) {
        this.jobType = _type;
    }

    public String getJobType() {
        return this.jobType;
    }

    public boolean hasModData() {
        return this.table != null && !this.table.isEmpty();
    }

    public KahluaTable getModData() {
        if (this.table == null) {
            this.table = LuaManager.platform.newTable();
        }

        return this.table;
    }

    public void storeInByteData(IsoObject o) {
        tempBuffer.clear();

        try {
            o.save(tempBuffer, false);
        } catch (IOException iOException) {
            iOException.printStackTrace();
        }

        tempBuffer.flip();
        if (this.byteData == null || this.byteData.capacity() < tempBuffer.limit() - 2 + 8) {
            this.byteData = ByteBuffer.allocate(tempBuffer.limit() - 2 + 8);
        }

        tempBuffer.get();
        tempBuffer.get();
        this.byteData.clear();
        this.byteData.put((byte)87);
        this.byteData.put((byte)86);
        this.byteData.put((byte)69);
        this.byteData.put((byte)82);
        this.byteData.putInt(238);
        this.byteData.put(tempBuffer);
        this.byteData.flip();
    }

    public ByteBuffer getByteData() {
        return this.byteData;
    }

    public IsoDeadBody loadCorpseFromByteData(IsoGridSquare square) {
        if (this.getByteData() == null) {
            return this.createAndStoreDefaultDeadBody(square);
        } else {
            Object object;
            try {
                try {
                    return this.tryLoadCorpseFromByteData(square);
                } catch (IOException iOException) {
                    ExceptionLogger.logException(iOException);
                }

                try {
                    return this.createDefaultDeadBody(square);
                } catch (Throwable throwable) {
                    ExceptionLogger.logException(throwable);
                    object = null;
                }
            } finally {
                this.getByteData().rewind();
            }

            return (IsoDeadBody)object;
        }
    }

    private IsoDeadBody tryLoadCorpseFromByteData(IsoGridSquare square) throws IOException {
        this.getByteData().rewind();
        byte byte0 = this.getByteData().get();
        byte byte1 = this.getByteData().get();
        byte byte2 = this.getByteData().get();
        byte byte3 = this.getByteData().get();
        if (byte0 == 87 && byte1 == 86 && byte2 == 69 && byte3 == 82) {
            int int0 = this.getByteData().getInt();
            IsoDeadBody deadBody = new IsoDeadBody(IsoWorld.instance.CurrentCell);
            deadBody.load(this.getByteData(), int0);
            if ("CorpseAnimal".equalsIgnoreCase(this.getType())) {
                Object object = this.hasModData() ? this.getModData().rawget("skeleton") : null;
                if (object != null && "true".equalsIgnoreCase(object.toString())) {
                    deadBody.getModData().rawset("skeleton", "true");
                }

                double double0 = this.getAge() * 24.0;
                if (deadBody.getModData().rawget("deathAge") instanceof Double double1) {
                    double0 += double1;
                    double0 -= PZMath.min((float)double0, deadBody.getInitialItemAge(this) * 24.0F);
                }

                deadBody.setDeathTime((float)(GameTime.getInstance().getWorldAgeHours() - double0));
                deadBody.getModData().rawset("deathAge", double0);
            }

            if (square != null) {
                deadBody.setSquare(square);
                deadBody.setCurrent(square);
            }

            return deadBody;
        } else {
            throw new IOException("expected 'WVER' signature in byteData");
        }
    }

    public boolean isForceDropHeavyItem() {
        return this.isHumanCorpse() || "Generator".equalsIgnoreCase(this.getType()) || this.hasTag("HeavyItem") || "Animal".equalsIgnoreCase(this.getType());
    }

    public boolean isHumanCorpse() {
        String string = this.getType();
        return "CorpseFemale".equalsIgnoreCase(string) ? true : "CorpseMale".equalsIgnoreCase(string);
    }

    public boolean isAnimalCorpse() {
        String string = this.getType();
        return "CorpseAnimal".equalsIgnoreCase(string);
    }

    private IsoDeadBody createDefaultDeadBody(IsoGridSquare square) throws Throwable {
        if (this.isHumanCorpse()) {
            IsoZombie zombie = new IsoZombie(IsoWorld.instance.CurrentCell);
            zombie.setDir(IsoDirections.fromIndex(Rand.Next(8)));
            zombie.setForwardDirection(zombie.dir.ToVector());
            zombie.setFakeDead(false);
            zombie.setHealth(0.0F);
            zombie.upKillCount = false;
            if (square != null) {
                zombie.dressInRandomOutfit();
            } else if (!zombie.isSkeleton()) {
                Object object = null;
                Outfit outfit = ZombiesZoneDefinition.getRandomDefaultOutfit(zombie.isFemale(), (String)object);
                UnderwearDefinition.addRandomUnderwear(zombie);
                zombie.dressInPersistentOutfit(outfit.m_Name);
            }

            zombie.DoZombieInventory();
            if (square != null) {
                zombie.setSquare(square);
                zombie.setCurrent(square);
            }

            return new IsoDeadBody(zombie, true, square != null);
        } else if (this.isAnimalCorpse()) {
            AnimalDefinitions animalDefinitions = PZArrayUtil.pickRandom(AnimalDefinitions.getAnimalDefsArray());
            if (animalDefinitions == null) {
                return null;
            } else {
                AnimalBreed animalBreed = animalDefinitions.getRandomBreed();
                if (animalBreed == null) {
                    return null;
                } else {
                    IsoAnimal animal = new IsoAnimal(IsoWorld.instance.CurrentCell, 0, 0, 0, animalDefinitions.getAnimalType(), animalBreed.getName());
                    animal.setDir(IsoDirections.fromIndex(Rand.Next(8)));
                    animal.setForwardDirection(animal.getDir().ToVector());
                    animal.setHealth(0.0F);
                    if (square != null) {
                        animal.setSquare(square);
                        animal.setCurrent(square);
                    }

                    IsoDeadBody deadBody = new IsoDeadBody(animal, true, square != null);
                    this.copyModData(deadBody.getModData());
                    this.setIcon(Texture.getSharedTexture(deadBody.invIcon));
                    if (deadBody.isAnimalSkeleton()) {
                        this.setName(Translator.getText("IGUI_Item_AnimalSkeleton", deadBody.customName));
                    } else {
                        this.setName(Translator.getText("IGUI_Item_AnimalCorpse", deadBody.customName));
                    }

                    this.setCustomName(true);
                    this.setActualWeight(deadBody.weight);
                    this.setWeight(deadBody.weight);
                    this.setCustomWeight(true);
                    return deadBody;
                }
            }
        } else {
            return null;
        }
    }

    public IsoDeadBody createAndStoreDefaultDeadBody(IsoGridSquare square) {
        try {
            IsoDeadBody deadBody = this.createDefaultDeadBody(square);
            if (deadBody != null) {
                this.storeInByteData(deadBody);
            }

            return deadBody;
        } catch (Throwable throwable) {
            ExceptionLogger.logException(throwable);
            return null;
        }
    }

    public boolean isRequiresEquippedBothHands() {
        return this.RequiresEquippedBothHands;
    }

    public float getA() {
        return this.col.a;
    }

    public float getR() {
        return this.col.r;
    }

    public float getG() {
        return this.col.g;
    }

    public float getB() {
        return this.col.b;
    }

    public InventoryItem(String _module, String _name, String _type, String tex) {
        this.col = Color.white;
        this.texture = Texture.trygetTexture(tex);
        if (this.texture == null) {
            this.texture = Texture.getSharedTexture("media/inventory/Question_On.png");
        }

        this.module = _module;
        this.name = _name;
        this.originalName = _name;
        this.type = _type;
        this.fullType = _module + "." + _type;
        this.WorldTexture = tex.replace("Item_", "media/inventory/world/WItem_");
        this.WorldTexture = this.WorldTexture + ".png";
    }

    public InventoryItem(String _module, String _name, String _type, Item item) {
        this.col = Color.white;
        this.texture = item.NormalTexture;
        this.module = _module;
        this.name = _name;
        this.originalName = _name;
        this.type = _type;
        this.fullType = _module + "." + _type;
        this.WorldTexture = item.WorldTextureName;
    }

    public String getType() {
        return this.type;
    }

    public Texture getTex() {
        return this.texture;
    }

    public String getCategory() {
        return this.mainCategory != null ? this.mainCategory : "Item";
    }

    public boolean UseForCrafting(int var1) {
        return false;
    }

    public boolean IsRotten() {
        return this.Age > this.OffAge;
    }

    public float HowRotten() {
        if (this.OffAgeMax - this.OffAge == 0) {
            return this.Age > this.OffAge ? 1.0F : 0.0F;
        } else {
            return (this.Age - this.OffAge) / (this.OffAgeMax - this.OffAge);
        }
    }

    public boolean CanStack(InventoryItem item) {
        return false;
    }

    public boolean ModDataMatches(InventoryItem item) {
        KahluaTable table0 = item.getModData();
        KahluaTable table1 = item.getModData();
        if (table0 == null && table1 == null) {
            return true;
        } else if (table0 == null) {
            return false;
        } else if (table1 == null) {
            return false;
        } else if (table0.len() != table1.len()) {
            return false;
        } else {
            KahluaTableIterator kahluaTableIterator = table0.iterator();

            while (kahluaTableIterator.advance()) {
                Object object0 = table1.rawget(kahluaTableIterator.getKey());
                Object object1 = kahluaTableIterator.getValue();
                if (!object0.equals(object1)) {
                    return false;
                }
            }

            return true;
        }
    }

    public void DoTooltip(ObjectTooltip tooltipUI) {
        this.DoTooltipEmbedded(tooltipUI, null, 0);
    }

    public void DoTooltipEmbedded(ObjectTooltip objectTooltip, ObjectTooltip.Layout layout1, int int3) {
        objectTooltip.render();
        UIFont uIFont = objectTooltip.getFont();
        int int0 = objectTooltip.getLineSpacing();
        int int1 = int0;
        int int2 = objectTooltip.padTop + int3;
        IsoPlayer player = Type.tryCastTo(objectTooltip.getCharacter(), IsoPlayer.class);
        String string0;
        if (player != null) {
            string0 = this.getName(player);
        } else {
            string0 = this.getName();
        }

        objectTooltip.DrawText(uIFont, string0, objectTooltip.padLeft, int2, 1.0, 1.0, 0.8F, 1.0);
        objectTooltip.adjustWidth(objectTooltip.padLeft, string0);
        ColorInfo colorInfo0 = Core.getInstance().getGoodHighlitedColor();
        ColorInfo colorInfo1 = Core.getInstance().getBadHighlitedColor();
        float float0 = colorInfo0.getR();
        float float1 = colorInfo0.getG();
        float float2 = colorInfo0.getB();
        float float3 = colorInfo1.getR();
        float float4 = colorInfo1.getG();
        float float5 = colorInfo1.getB();
        int2 += int0 + 5;
        if (this.extraItems != null && !this.extraItems.isEmpty()) {
            objectTooltip.DrawText(uIFont, Translator.getText("Tooltip_item_Contains"), objectTooltip.padLeft, int2, 1.0, 1.0, 0.8F, 1.0);
            int int4 = objectTooltip.padLeft + TextManager.instance.MeasureStringX(uIFont, Translator.getText("Tooltip_item_Contains")) + 4;
            int int5 = (int0 - int0) / 2;

            for (int int6 = 0; int6 < this.extraItems.size(); int6++) {
                InventoryItem item1 = InventoryItemFactory.CreateItem(this.extraItems.get(int6));
                if (!this.IsCookable && item1.IsCookable) {
                    item1.setCooked(true);
                }

                if (this.isCooked() && item1.IsCookable) {
                    item1.setCooked(true);
                }

                float float6 = this.drawTooltipItemTexture(objectTooltip, item1.getTex(), int4, int2 + int5, int1, int1, 1.0F, 1.0F, 1.0F, 1.0F);
                int4 = int4 + (int)PZMath.ceil(float6) + 2;
            }

            int2 = int2 + int0 + 5;
        }

        if (this instanceof Food && ((Food)this).spices != null) {
            objectTooltip.DrawText(uIFont, Translator.getText("Tooltip_item_Spices"), objectTooltip.padLeft, int2, 1.0, 1.0, 0.8F, 1.0);
            int int7 = objectTooltip.padLeft + TextManager.instance.MeasureStringX(uIFont, Translator.getText("Tooltip_item_Spices")) + 4;
            int int8 = (int0 - int1) / 2;

            for (int int9 = 0; int9 < ((Food)this).spices.size(); int9++) {
                InventoryItem item2 = InventoryItemFactory.CreateItem(((Food)this).spices.get(int9));
                float float7 = this.drawTooltipItemTexture(objectTooltip, item2.getTex(), int7, int2 + int8, int1, int1, 1.0F, 1.0F, 1.0F, 1.0F);
                int7 = int7 + (int)PZMath.ceil(float7) + 2;
            }

            int2 = int2 + int0 + 5;
        }

        ObjectTooltip.Layout layout0;
        if (layout1 != null) {
            layout0 = layout1;
            layout1.offsetY = int2;
        } else {
            layout0 = objectTooltip.beginLayout();
            layout0.setMinLabelWidth(80);
        }

        if (SandboxOptions.instance.isUnstableScriptNameSpam()) {
            ObjectTooltip.LayoutItem layoutItem0 = layout0.addItem();
            layoutItem0.setLabel(Translator.getText("Item Report") + ":", 1.0F, 0.4F, 0.7F, 1.0F);
            layoutItem0.setValue(this.getFullType(), 1.0F, 1.0F, 0.8F, 1.0F);
        }

        if (player != null && this.getScriptItem() != null && !this.getScriptItem().getResearchableRecipes(player).isEmpty()) {
            ColorInfo colorInfo2 = Core.getInstance().getGoodHighlitedColor();
            ObjectTooltip.LayoutItem layoutItem1 = layout0.addItem();
            if (this.getScriptItem().getResearchableRecipes(player).size() == 1) {
                layoutItem1.setLabel(Translator.getText("Tooltip_item_CanResearch"), colorInfo2.getR(), colorInfo2.getG(), colorInfo2.getB(), 1.0F);
            } else {
                layoutItem1.setLabel(Translator.getText("Tooltip_item_CanResearchPlural"), colorInfo2.getR(), colorInfo2.getG(), colorInfo2.getB(), 1.0F);
            }
        }

        if (player != null && this.getScriptItem() != null && this.getScriptItem().isFavouriteRecipeInput(player)) {
            ColorInfo colorInfo3 = Core.getInstance().getGoodHighlitedColor();
            ObjectTooltip.LayoutItem layoutItem2 = layout0.addItem();
            layoutItem2.setLabel(Translator.getText("Tooltip_item_IsFavouriteInput"), colorInfo3.getR(), colorInfo3.getG(), colorInfo3.getB(), 1.0F);
        }

        if (player != null && this.isNoRecipes(player)) {
            ColorInfo colorInfo4 = Core.getInstance().getBadHighlitedColor();
            ObjectTooltip.LayoutItem layoutItem3 = layout0.addItem();
            layoutItem3.setLabel(Translator.getText("Tooltip_NoRecipes_More"), colorInfo4.getR(), colorInfo4.getG(), colorInfo4.getB(), 1.0F);
        }

        if (player != null && this.isUnwanted(player)) {
            ColorInfo colorInfo5 = Core.getInstance().getBadHighlitedColor();
            ObjectTooltip.LayoutItem layoutItem4 = layout0.addItem();
            layoutItem4.setLabel(Translator.getText("Tooltip_Unwanted_More"), colorInfo5.getR(), colorInfo5.getG(), colorInfo5.getB(), 1.0F);
        }

        ObjectTooltip.LayoutItem layoutItem5 = layout0.addItem();
        layoutItem5.setLabel(Translator.getText("Tooltip_item_Weight") + ":", 1.0F, 1.0F, 0.8F, 1.0F);
        boolean boolean0 = this.isEquipped();
        if (!(this instanceof HandWeapon)
            && !(this instanceof Clothing)
            && !(this instanceof DrainableComboItem)
            && !this.getFullType().contains("Walkie")
            && !this.isKeyRing()) {
            if (this instanceof AnimalInventoryItem) {
                layoutItem5.setValueRightNoPlus(this.getWeight());
            } else {
                float float8 = this.getUnequippedWeight();
                if (float8 > 0.0F && float8 < 0.01F) {
                    float8 = 0.01F;
                }

                if (this.getAttachedSlot() > -1) {
                    layoutItem5.setValue(
                        this.getCleanString(this.getHotbarEquippedWeight())
                            + "    ("
                            + this.getCleanString(this.getUnequippedWeight())
                            + " "
                            + Translator.getText("Tooltip_item_Unattached")
                            + ")",
                        1.0F,
                        1.0F,
                        1.0F,
                        1.0F
                    );
                } else {
                    layoutItem5.setValueRightNoPlus(float8);
                }
            }
        } else if (!boolean0 && !this.isFakeEquipped()) {
            if (this.getAttachedSlot() > -1) {
                layoutItem5.setValue(
                    this.getCleanString(this.getHotbarEquippedWeight())
                        + "    ("
                        + this.getCleanString(this.getUnequippedWeight())
                        + " "
                        + Translator.getText("Tooltip_item_Unattached")
                        + ")",
                    1.0F,
                    1.0F,
                    1.0F,
                    1.0F
                );
            } else {
                layoutItem5.setValue(
                    this.getCleanString(this.getUnequippedWeight())
                        + "    ("
                        + this.getCleanString(this.getEquippedWeight())
                        + " "
                        + Translator.getText("Tooltip_item_Equipped")
                        + ")",
                    1.0F,
                    1.0F,
                    1.0F,
                    1.0F
                );
            }
        } else {
            layoutItem5.setValue(
                this.getCleanString(this.getEquippedWeight())
                    + "    ("
                    + this.getCleanString(this.getUnequippedWeight())
                    + " "
                    + Translator.getText("Tooltip_item_Unequipped")
                    + ")",
                1.0F,
                1.0F,
                1.0F,
                1.0F
            );
        }

        if (objectTooltip.getWeightOfStack() > 0.0F) {
            layoutItem5 = layout0.addItem();
            layoutItem5.setLabel(Translator.getText("Tooltip_item_StackWeight") + ":", 1.0F, 1.0F, 0.8F, 1.0F);
            float float9 = objectTooltip.getWeightOfStack();
            if (float9 > 0.0F && float9 < 0.01F) {
                float9 = 0.01F;
            }

            layoutItem5.setValueRightNoPlus(float9);
        }

        if (this.getMaxAmmo() > 0 && !(this instanceof HandWeapon)) {
            layoutItem5 = layout0.addItem();
            layoutItem5.setLabel(Translator.getText("Tooltip_weapon_AmmoCount") + ":", 1.0F, 1.0F, 0.8F, 1.0F);
            layoutItem5.setValue(this.getCurrentAmmoCount() + " / " + this.getMaxAmmo(), 1.0F, 1.0F, 1.0F, 1.0F);
        }

        if (!(this instanceof HandWeapon) && this.getAmmoType() != null) {
            layoutItem5 = layout0.addItem();
            layoutItem5.setLabel(Translator.getText("ContextMenu_AmmoType") + ":", 1.0F, 1.0F, 0.8F, 1.0F);
            String string1 = InventoryItemFactory.<InventoryItem>CreateItem(this.getAmmoType()).getDisplayName();
            layoutItem5.setValue(Translator.getText(string1), 1.0F, 1.0F, 1.0F, 1.0F);
        }

        if (this.gunType != null) {
            Item item3 = ScriptManager.instance.FindItem(this.getGunType());
            if (item3 == null) {
                item3 = ScriptManager.instance.FindItem(this.getModule() + "." + this.ammoType);
            }

            if (item3 != null) {
                layoutItem5 = layout0.addItem();
                layoutItem5.setLabel(Translator.getText("ContextMenu_GunType") + ":", 1.0F, 1.0F, 0.8F, 1.0F);
                layoutItem5.setValue(item3.getDisplayName(), 1.0F, 1.0F, 1.0F, 1.0F);
            }
        }

        if (Core.bDebug && DebugOptions.instance.TooltipInfo.getValue()) {
            layoutItem5 = layout0.addItem();
            layoutItem5.setLabel("getActualWeight()", 1.0F, 1.0F, 0.8F, 1.0F);
            layoutItem5.setValueRightNoPlus(this.getActualWeight());
            layoutItem5 = layout0.addItem();
            layoutItem5.setLabel("getWeight()", 1.0F, 1.0F, 0.8F, 1.0F);
            layoutItem5.setValueRightNoPlus(this.getWeight());
            layoutItem5 = layout0.addItem();
            layoutItem5.setLabel("getEquippedWeight()", 1.0F, 1.0F, 0.8F, 1.0F);
            layoutItem5.setValueRightNoPlus(this.getEquippedWeight());
            layoutItem5 = layout0.addItem();
            layoutItem5.setLabel("getUnequippedWeight()", 1.0F, 1.0F, 0.8F, 1.0F);
            layoutItem5.setValueRightNoPlus(this.getUnequippedWeight());
            layoutItem5 = layout0.addItem();
            layoutItem5.setLabel("getContentsWeight()", 1.0F, 1.0F, 0.8F, 1.0F);
            layoutItem5.setValueRightNoPlus(this.getContentsWeight());
            if (this instanceof Key || "Doorknob".equals(this.type)) {
                layoutItem5 = layout0.addItem();
                layoutItem5.setLabel("DBG: keyId", 1.0F, 1.0F, 0.8F, 1.0F);
                layoutItem5.setValueRightNoPlus(this.getKeyId());
            }

            layoutItem5 = layout0.addItem();
            layoutItem5.setLabel("ID", 1.0F, 1.0F, 0.8F, 1.0F);
            layoutItem5.setValueRightNoPlus(this.id);
            layoutItem5 = layout0.addItem();
            layoutItem5.setLabel("DictionaryID", 1.0F, 1.0F, 0.8F, 1.0F);
            layoutItem5.setValueRightNoPlus(this.getRegistry_id());
            ClothingItem clothingItem = this.getClothingItem();
            if (clothingItem != null) {
                layoutItem5 = layout0.addItem();
                layoutItem5.setLabel("ClothingItem", 1.0F, 1.0F, 1.0F, 1.0F);
                layoutItem5.setValue(this.getClothingItem().m_Name, 1.0F, 1.0F, 1.0F, 1.0F);
            }
        }

        if (Core.bDebug && DebugOptions.instance.TooltipInfo.getValue() || LuaManager.GlobalObject.isAdmin()) {
            layoutItem5 = layout0.addItem();
            String string2 = "Loot Category";
            String string3 = Translator.getText("Sandbox_" + this.getLootType() + "LootNew");
            layoutItem5.setLabel(string2 + ":", 1.0F, 1.0F, 0.8F, 1.0F);
            layoutItem5.setValue(string3, 1.0F, 1.0F, 1.0F, 1.0F);
        }

        if (this instanceof DrainableComboItem && !this.hasTag("HideRemaining")) {
            layoutItem5 = layout0.addItem();
            layoutItem5.setLabel(Translator.getText("IGUI_invpanel_Remaining") + ": ", 1.0F, 1.0F, 0.8F, 1.0F);
            float float10 = this.getCurrentUsesFloat();
            ColorInfo colorInfo6 = new ColorInfo();
            Core.getInstance().getBadHighlitedColor().interp(Core.getInstance().getGoodHighlitedColor(), float10, colorInfo6);
            layoutItem5.setProgress(float10, colorInfo6.getR(), colorInfo6.getG(), colorInfo6.getB(), 1.0F);
        }

        if (this instanceof Food && ((Food)this).isTainted() && SandboxOptions.instance.EnableTaintedWaterText.getValue()) {
            layoutItem5 = layout0.addItem();
            if (!this.hasMetal()) {
                layoutItem5.setLabel(Translator.getText("Tooltip_item_TaintedWater"), 1.0F, 0.5F, 0.5F, 1.0F);
            } else {
                layoutItem5.setLabel(Translator.getText("Tooltip_item_TaintedWater_Plastic"), 1.0F, 0.5F, 0.5F, 1.0F);
            }
        }

        if (!this.getScriptItem().getForageFocusCategories().isEmpty()) {
            for (String string4 : this.getScriptItem().getForageFocusCategories()) {
                layoutItem5 = layout0.addItem();
                layoutItem5.setLabel(Translator.getText("UI_search_mode_focus") + ":", 1.0F, 1.0F, 0.8F, 1.0F);
                layoutItem5.setValue(Translator.getText("IGUI_SearchMode_Categories_" + string4), 1.0F, 1.0F, 1.0F, 1.0F);
            }
        }

        if (this.getFatigueChange() != 0.0F) {
            layoutItem5 = layout0.addItem();
            layoutItem5.setLabel(Translator.getText("Tooltip_item_Fatigue") + ": ", 1.0F, 1.0F, 0.8F, 1.0F);
            if (this.getFatigueChange() < 0.0F) {
                layoutItem5.setProgress(this.getFatigueChange() * -1.0F, float0, float1, float2, 1.0F);
            } else {
                layoutItem5.setProgress(this.getFatigueChange(), float3, float4, float5, 1.0F);
            }
        }

        this.DoTooltip(objectTooltip, layout0);
        if (this.getRemoteControlID() != -1) {
            layoutItem5 = layout0.addItem();
            layoutItem5.setLabel(Translator.getText("Tooltip_TrapControllerID"), 1.0F, 1.0F, 0.8F, 1.0F);
            layoutItem5.setValue(Integer.toString(this.getRemoteControlID()), 1.0F, 1.0F, 0.8F, 1.0F);
        }

        if (this.getHaveBeenRepaired() > 0) {
            layoutItem5 = layout0.addItem();
            layoutItem5.setLabel(Translator.getText("Tooltip_weapon_Repaired") + ":", 1.0F, 1.0F, 0.8F, 1.0F);
            if (this.hasTimesHeadRepaired()) {
                layoutItem5.setLabel(Translator.getText("Tooltip_handle_Repaired") + ":", 1.0F, 1.0F, 0.8F, 1.0F);
            }

            layoutItem5.setValue(this.getHaveBeenRepaired() + "x", 1.0F, 1.0F, 1.0F, 1.0F);
        }

        if (this.hasTimesHeadRepaired() && this.getTimesHeadRepaired() > 0) {
            layoutItem5 = layout0.addItem();
            layoutItem5.setLabel(Translator.getText("Tooltip_head_Repaired") + ":", 1.0F, 1.0F, 0.8F, 1.0F);
            layoutItem5.setValue(this.getTimesHeadRepaired() + "x", 1.0F, 1.0F, 1.0F, 1.0F);
        }

        if (this.isEquippedNoSprint()) {
            layoutItem5 = layout0.addItem();
            layoutItem5.setLabel(Translator.getText("Tooltip_CantSprintEquipped"), 1.0F, 0.1F, 0.1F, 1.0F);
        }

        if (this.isWet()) {
            layoutItem5 = layout0.addItem();
            layoutItem5.setLabel(Translator.getText("Tooltip_Wetness") + ": ", 1.0F, 1.0F, 0.8F, 1.0F);
            float float11 = this.getWetCooldown() / 10000.0F;
            ColorInfo colorInfo7 = new ColorInfo();
            Core.getInstance().getGoodHighlitedColor().interp(Core.getInstance().getBadHighlitedColor(), float11, colorInfo7);
            layoutItem5.setProgress(float11, colorInfo7.getR(), colorInfo7.getG(), colorInfo7.getB(), 1.0F);
        }

        if (this.getMaxCapacity() > 0) {
            layoutItem5 = layout0.addItem();
            layoutItem5.setLabel(Translator.getText("Tooltip_container_Capacity") + ":", 1.0F, 1.0F, 0.8F, 1.0F);
            float float12 = this.getMaxCapacity();
            if (this.isConditionAffectsCapacity()) {
                float12 = VehiclePart.getNumberByCondition(this.getMaxCapacity(), this.getCondition(), 5.0F);
            }

            if (this.getItemCapacity() > -1.0F) {
                layoutItem5.setValue(this.getItemCapacity() + " / " + float12, 1.0F, 1.0F, 0.8F, 1.0F);
            } else {
                layoutItem5.setValue("0 / " + float12, 1.0F, 1.0F, 0.8F, 1.0F);
            }
        }

        if (!(this instanceof HandWeapon) && this.hasSharpness()) {
            ColorInfo colorInfo8 = new ColorInfo();
            layoutItem5 = layout0.addItem();
            layoutItem5.setLabel(Translator.getText("Tooltip_weapon_Sharpness") + ":", 1.0F, 1.0F, 0.8F, 1.0F);
            float float13 = this.getSharpness();
            Core.getInstance().getBadHighlitedColor().interp(Core.getInstance().getGoodHighlitedColor(), float13, colorInfo8);
            layoutItem5.setProgress(float13, colorInfo8.getR(), colorInfo8.getG(), colorInfo8.getB(), 1.0F);
        }

        if (!(this instanceof HandWeapon)
            && !(this instanceof Clothing)
            && this.getConditionMax() > 0
            && (this.getMechanicType() > 0 || this.hasTag("ShowCondition") || this.getConditionMax() > this.getCondition())) {
            ColorInfo colorInfo9 = new ColorInfo();
            float float14 = 1.0F;
            float float15 = 1.0F;
            float float16 = 0.8F;
            float float17 = 1.0F;
            layoutItem5 = layout0.addItem();
            String string5 = "Tooltip_weapon_Condition";
            if (this.hasHeadCondition()) {
                string5 = "Tooltip_weapon_HandleCondition";
            }

            layoutItem5.setLabel(Translator.getText(string5) + ":", float14, float15, float16, float17);
            float float18 = (float)this.getCondition() / this.getConditionMax();
            Core.getInstance().getBadHighlitedColor().interp(Core.getInstance().getGoodHighlitedColor(), float18, colorInfo9);
            layoutItem5.setProgress(float18, colorInfo9.getR(), colorInfo9.getG(), colorInfo9.getB(), 1.0F);
        }

        if (this.isRecordedMedia()) {
            MediaData mediaData = this.getMediaData();
            if (mediaData != null) {
                if (mediaData.getTranslatedTitle() != null) {
                    layoutItem5 = layout0.addItem();
                    layoutItem5.setLabel(Translator.getText("Tooltip_media_title") + ":", 1.0F, 1.0F, 0.8F, 1.0F);
                    layoutItem5.setValue(mediaData.getTranslatedTitle(), 1.0F, 1.0F, 1.0F, 1.0F);
                    if (mediaData.getTranslatedSubTitle() != null) {
                        layoutItem5 = layout0.addItem();
                        layoutItem5.setLabel("", 1.0F, 1.0F, 0.8F, 1.0F);
                        layoutItem5.setValue(mediaData.getTranslatedSubTitle(), 1.0F, 1.0F, 1.0F, 1.0F);
                    }
                }

                if (mediaData.getTranslatedAuthor() != null) {
                    layoutItem5 = layout0.addItem();
                    layoutItem5.setLabel(Translator.getText("Tooltip_media_author") + ":", 1.0F, 1.0F, 0.8F, 1.0F);
                    layoutItem5.setValue(mediaData.getTranslatedAuthor(), 1.0F, 1.0F, 1.0F, 1.0F);
                }
            }

            if (objectTooltip.getCharacter() instanceof IsoPlayer && this.hasBeenSeen((IsoPlayer)objectTooltip.getCharacter())) {
                layoutItem5 = layout0.addItem();
                String string6 = Translator.getText("ContextMenu_Watched");
                layoutItem5.setLabel(string6, 1.0F, 1.0F, 0.8F, 1.0F);
            }

            if (objectTooltip.getCharacter() instanceof IsoPlayer && this.hasBeenHeard((IsoPlayer)objectTooltip.getCharacter())) {
                layoutItem5 = layout0.addItem();
                String string7 = Translator.getText("ContextMenu_Heard");
                layoutItem5.setLabel(string7, 1.0F, 1.0F, 0.8F, 1.0F);
            }
        }

        if (this.hasTag("Compass") && this.isInPlayerInventory()) {
            IsoDirections directions = this.getOutermostContainer().getParent().getDir();
            layoutItem5 = layout0.addItem();
            layoutItem5.setLabel(Translator.getText("Tooltip_compass_" + directions.toCompassString()), 1.0F, 1.0F, 0.8F, 1.0F);
        }

        if (this.isFishingLure()) {
            layoutItem5 = layout0.addItem();
            layoutItem5.setLabel(Translator.getText("Tooltip_IsFishingLure"), 1.0F, 1.0F, 0.8F, 1.0F);
        }

        if (this.getAttributes() != null) {
            this.getAttributes().DoTooltip(objectTooltip, layout0);
        }

        if (this.getFluidContainer() != null) {
            this.getFluidContainer().DoTooltip(objectTooltip, layout0);
        }

        if (this.getWorldItem() != null && this.getWorldItem().getFluidContainer() != null) {
            this.getWorldItem().getFluidContainer().DoTooltip(objectTooltip, layout0);
        }

        if (this.getDurabilityComponent() != null) {
            this.getDurabilityComponent().DoTooltip(objectTooltip, layout0);
        }

        if (this.getVisionModifier() != 1.0F) {
            layoutItem5 = layout0.addItem();
            layoutItem5.setLabel(Translator.getText("Tooltip_item_VisionImpariment") + ": ", 1.0F, 1.0F, 0.8F, 1.0F);
            if (this.getVisionModifier() < 1.0F) {
                layoutItem5.setProgress(1.0F - this.getVisionModifier(), float3, float4, float5, 1.0F);
            } else {
                layoutItem5.setProgress(this.getVisionModifier() - 1.0F, float0, float1, float2, 1.0F);
            }
        }

        if (this.getHearingModifier() != 1.0F) {
            layoutItem5 = layout0.addItem();
            layoutItem5.setLabel(Translator.getText("Tooltip_item_HearingImpariment") + ": ", 1.0F, 1.0F, 0.8F, 1.0F);
            if (this.getHearingModifier() < 1.0F) {
                layoutItem5.setProgress(1.0F - this.getHearingModifier(), float3, float4, float5, 1.0F);
            } else {
                layoutItem5.setProgress(this.getHearingModifier() - 1.0F, float0, float1, float2, 1.0F);
            }
        }

        if (this.getDiscomfortModifier() != 0.0F) {
            layoutItem5 = layout0.addItem();
            layoutItem5.setLabel(Translator.getText("Tooltip_item_Discomfort") + ": ", 1.0F, 1.0F, 0.8F, 1.0F);
            if (this.getDiscomfortModifier() > 0.0F) {
                layoutItem5.setProgress(this.getDiscomfortModifier(), float3, float4, float5, 1.0F);
            } else {
                layoutItem5.setProgress(this.getDiscomfortModifier() * -1.0F, float0, float1, float2, 1.0F);
            }
        }

        if (Core.getInstance().getOptionShowItemModInfo() && !this.isVanilla()) {
            layoutItem5 = layout0.addItem();
            Color color = Colors.CornFlowerBlue;
            layoutItem5.setLabel("Mod: " + this.getModName(), color.r, color.g, color.b, 1.0F);
            ItemInfo itemInfo = WorldDictionary.getItemInfoFromID(this.getRegistry_id());
            if (itemInfo != null && itemInfo.getModOverrides() != null) {
                layoutItem5 = layout0.addItem();
                float float19 = 0.5F;
                if (itemInfo.getModOverrides().size() == 1) {
                    layoutItem5.setLabel(
                        "This item overrides: " + WorldDictionary.getModNameFromID(itemInfo.getModOverrides().get(0)), float19, float19, float19, 1.0F
                    );
                } else {
                    layoutItem5.setLabel("This item overrides:", float19, float19, float19, 1.0F);

                    for (int int10 = 0; int10 < itemInfo.getModOverrides().size(); int10++) {
                        layoutItem5 = layout0.addItem();
                        layoutItem5.setLabel(" - " + WorldDictionary.getModNameFromID(itemInfo.getModOverrides().get(int10)), float19, float19, float19, 1.0F);
                    }
                }
            }
        }

        if (this.getTooltip() != null) {
            layoutItem5 = layout0.addItem();
            layoutItem5.setLabel(Translator.getText(this.getTooltip()), 1.0F, 1.0F, 0.8F, 1.0F);
        }

        if (layout1 == null) {
            int2 = layout0.render(objectTooltip.padLeft, int2, objectTooltip);
            objectTooltip.endLayout(layout0);
            int2 += objectTooltip.padBottom;
            objectTooltip.setHeight(int2);
            if (objectTooltip.getWidth() < 150.0) {
                objectTooltip.setWidth(150.0);
            }
        }
    }

    private float drawTooltipItemTexture(
        ObjectTooltip objectTooltip,
        Texture texturex,
        float float7,
        float float6,
        float float5,
        float float4,
        float float3,
        float float2,
        float float1,
        float float0
    ) {
        objectTooltip.DrawTextureScaledAspect(texturex, float7, float6, float5, float4, float3, float2, float1, float0);
        if (texturex != null && texturex.getWidth() > 0 && texturex.getHeight() > 0) {
            float float8 = Math.min(float5 / texturex.getWidthOrig(), float4 / texturex.getHeightOrig());
            return PZMath.ceil(texturex.getWidth() * float8);
        } else {
            return float5;
        }
    }

    public String getCleanString(float weight) {
        float float0 = (int)((weight + 0.005) * 100.0) / 100.0F;
        return Float.toString(float0);
    }

    public void DoTooltip(ObjectTooltip tooltipUI, ObjectTooltip.Layout layout) {
    }

    public void SetContainerPosition(int x, int y) {
        this.containerX = x;
        this.containerY = y;
    }

    public void Use() {
        this.Use(false);
    }

    public void UseAndSync() {
        this.Use(false, false, GameServer.bServer);
    }

    public void UseItem() {
        this.Use(false);
    }

    public void Use(boolean bCrafting) {
        this.Use(bCrafting, false, false);
    }

    public void Use(boolean boolean0, boolean boolean1, boolean boolean2) {
        if (this.isDisappearOnUse() || boolean0) {
            this.setCurrentUses(this.getCurrentUses() - 1);
            if (this.replaceOnUse != null && !boolean1 && !boolean0 && this.container != null) {
                String string = this.replaceOnUse;
                if (!this.replaceOnUse.contains(".")) {
                    string = this.module + "." + string;
                }

                InventoryItem item1 = this.container.AddItem(string);
                if (item1 != null) {
                    item1.setColorRed(this.colorRed);
                    item1.setColorGreen(this.colorGreen);
                    item1.setColorBlue(this.colorBlue);
                    item1.setColor(new Color(this.colorRed, this.colorGreen, this.colorBlue));
                    item1.setCustomColor(true);
                    item1.setModelIndex(this.modelIndex);
                    this.container.setDrawDirty(true);
                    this.container.setDirty(true);
                    item1.copyConditionStatesFrom(this);
                    item1.setFavorite(this.isFavorite());
                    if (GameServer.bServer && boolean2) {
                        GameServer.sendAddItemToContainer(this.container, item1);
                    }
                }
            }

            if (this.getCurrentUses() <= 0) {
                if (this.isKeepOnDeplete()) {
                    return;
                }

                if (this.container != null) {
                    if (this.container.parent instanceof IsoGameCharacter && !(this instanceof HandWeapon)) {
                        IsoGameCharacter character = (IsoGameCharacter)this.container.parent;
                        character.removeFromHands(this);
                    }

                    this.container.Items.remove(this);
                    this.container.setDirty(true);
                    this.container.setDrawDirty(true);
                    if (GameServer.bServer && boolean2) {
                        GameServer.sendRemoveItemFromContainer(this.container, this);
                    }

                    this.container = null;
                }
            } else if (boolean2) {
                this.syncItemFields();
            }
        }
    }

    public boolean shouldUpdateInWorld() {
        if (!GameServer.bServer && this.itemHeat != 1.0F) {
            return true;
        } else if (!GameClient.bClient && (this.hasComponent(ComponentType.FluidContainer) || this instanceof Food)) {
            IsoGridSquare square = this.getWorldItem().getSquare();
            return square != null && square.isOutside();
        } else {
            return false;
        }
    }

    public void update() {
        if (this.isWet()) {
            this.wetCooldown = this.wetCooldown - 1.0F * GameTime.instance.getMultiplier();
            if (this.wetCooldown <= 0.0F) {
                InventoryItem item1 = InventoryItemFactory.CreateItem(this.itemWhenDry);
                if (this.isFavorite()) {
                    item1.setFavorite(true);
                }

                IsoWorldInventoryObject worldInventoryObject = this.getWorldItem();
                if (worldInventoryObject != null) {
                    IsoGridSquare square0 = worldInventoryObject.getSquare();
                    square0.AddWorldInventoryItem(
                        item1, worldInventoryObject.getX() % 1.0F, worldInventoryObject.getY() % 1.0F, worldInventoryObject.getZ() % 1.0F
                    );
                    square0.transmitRemoveItemFromSquare(worldInventoryObject);
                    if (this.getContainer() != null) {
                        this.getContainer().setDirty(true);
                        this.getContainer().setDrawDirty(true);
                    }

                    square0.chunk.recalcHashCodeObjects();
                    this.setWorldItem(null);
                } else if (this.getContainer() != null) {
                    this.getContainer().addItem(item1);
                    this.getContainer().Remove(this);
                }

                this.setWet(false);
                IsoWorld.instance.CurrentCell.addToProcessItemsRemove(this);
                LuaEventManager.triggerEvent("OnContainerUpdate");
            }
        }

        if (this.hasComponent(ComponentType.FluidContainer)) {
            ItemContainer containerx = this.getOutermostContainer();
            FluidContainer fluidContainer = this.getFluidContainer();
            if (containerx != null) {
                float float0 = containerx.getTemprature();
                float float1 = 0.001F;
                if (float0 == 1.0F && this.itemHeat < 1.0F) {
                    this.itemHeat = this.itemHeat + float1 * GameTime.instance.getMultiplier();
                    if (this.itemHeat > float0) {
                        this.itemHeat = float0;
                    }
                }

                if (this.itemHeat > float0) {
                    this.itemHeat = this.itemHeat - float1 * GameTime.instance.getMultiplier();
                    if (this.itemHeat < Math.max(0.2F, float0)) {
                        this.itemHeat = Math.max(0.2F, float0);
                    }
                }

                if (this.itemHeat < float0 && (this.hasTag("Cookable") || this.hasTag("CookableMicrowave") && containerx.getType().equals("microwave"))) {
                    this.itemHeat = this.itemHeat + float0 / 1000.0F * GameTime.instance.getMultiplier();
                    if (this.itemHeat > Math.min(3.0F, float0)) {
                        this.itemHeat = Math.min(3.0F, float0);
                    }
                }

                if (this.itemHeat > 1.6F && !fluidContainer.isEmpty()) {
                    if (fluidContainer.contains(Fluid.TaintedWater)) {
                        float float2 = fluidContainer.getSpecificFluidAmount(Fluid.TaintedWater);
                        float float3 = PZMath.min(float2, 0.01F * GameTime.instance.getMultiplier());
                        fluidContainer.adjustSpecificFluidAmount(Fluid.TaintedWater, float2 - float3);
                        fluidContainer.addFluid(Fluid.Water, float3);
                    }

                    if (fluidContainer.contains(Fluid.Petrol)) {
                        fluidContainer.removeFluid();
                        boolean boolean0 = this.container != null
                            && this.container.getParent() != null
                            && this.container.getParent().getName() != null
                            && this.container.getParent().getName().equals("Campfire");
                        if (!boolean0 && this.container != null && this.container.getParent() != null && this.container.getParent() instanceof IsoFireplace) {
                            boolean0 = true;
                        }

                        if (this.container != null && this.container.SourceGrid != null && !boolean0) {
                            IsoFireManager.StartFire(this.container.SourceGrid.getCell(), this.container.SourceGrid, true, 500000);
                        }
                    }
                }
            }
        }

        if ((this.container == null || this.getWorldItem() != null) && this.itemHeat != 1.0F) {
            float float4 = 1.0F;
            if (this.itemHeat > float4) {
                this.itemHeat = this.itemHeat - 0.001F * GameTime.instance.getMultiplier();
                if (this.itemHeat < float4) {
                    this.itemHeat = float4;
                }
            }

            if (this.itemHeat < float4) {
                this.itemHeat = this.itemHeat + 0.001F * GameTime.instance.getMultiplier();
                if (this.itemHeat > float4) {
                    this.itemHeat = float4;
                }
            }
        }

        if (!GameServer.bServer && this.getWorldItem() != null && RainManager.isRaining()) {
            IsoGridSquare square1 = this.getWorldItem().getSquare();
            if (this instanceof Food
                && square1 != null
                && square1.isOutside()
                && LuaManager.GlobalObject.ZombRandFloat(0.0F, 1.0F) < RainManager.getRainIntensity()) {
                ((Food)this).setTainted(true);
            }
        }
    }

    public boolean finishupdate() {
        if (!GameClient.bClient
            && this.getWorldItem() != null
            && this.getWorldItem().getObjectIndex() != -1
            && this instanceof Food
            && !((Food)this).isTainted()) {
            return false;
        } else if (this.getWorldItem() != null && this.itemHeat != 1.0F) {
            return false;
        } else {
            if (this.hasComponent(ComponentType.FluidContainer)) {
                FluidContainer fluidContainer = this.getFluidContainer();
                if (this.getWorldItem() != null && this.getWorldItem().getObjectIndex() != -1 && fluidContainer.canPlayerEmpty()) {
                    return false;
                }

                if (this.container != null
                    && (this.itemHeat != 1.0F || this.itemHeat != this.container.getTemprature() || this.container.isTemperatureChanging())) {
                    return false;
                }
            }

            return !this.isWet();
        }
    }

    public void updateSound(BaseSoundEmitter emitter) {
        this.updateEquippedAndActivatedSound(emitter);
    }

    public void updateEquippedAndActivatedSound(BaseSoundEmitter var1) {
        String string = this.getScriptItem().getSoundByID("EquippedAndActivated");
        if (string != null) {
            IsoPlayer player = this.getOwnerPlayer(this.getContainer());
            if (player == null) {
                this.stopEquippedAndActivatedSound();
                ItemSoundManager.removeItem(this);
            } else if (this.isEquipped() && this.isActivated()) {
                BaseCharacterSoundEmitter baseCharacterSoundEmitter = player.getEmitter();
                if (!baseCharacterSoundEmitter.isPlaying(this.equippedAndActivatedSound)) {
                    this.stopEquippedAndActivatedSound();
                    this.equippedAndActivatedPlayer = player;
                    this.equippedAndActivatedSound = baseCharacterSoundEmitter.playSoundImpl(string, player);
                }
            } else {
                this.stopEquippedAndActivatedSound();
                ItemSoundManager.removeItem(this);
            }
        }
    }

    public void updateEquippedAndActivatedSound() {
        String string = this.getScriptItem().getSoundByID("EquippedAndActivated");
        if (string != null) {
            if (this.isActivated() && this instanceof DrainableComboItem && this.getCurrentUses() <= 0) {
                this.setActivated(false);
            }

            if (this.isEquipped() && this.isActivated()) {
                ItemSoundManager.addItem(this);
            } else {
                this.stopEquippedAndActivatedSound();
                ItemSoundManager.removeItem(this);
            }
        }
    }

    protected void stopEquippedAndActivatedSound() {
        if (this.equippedAndActivatedPlayer != null && this.equippedAndActivatedSound != 0L) {
            this.equippedAndActivatedPlayer.getEmitter().stopOrTriggerSound(this.equippedAndActivatedSound);
            this.equippedAndActivatedPlayer = null;
            this.equippedAndActivatedSound = 0L;
        }
    }

    public void playActivateSound() {
        String string = this.getScriptItem().getSoundByID("Activate");
        if (string != null) {
            this.playSoundOnPlayer(string);
        }
    }

    public void playDeactivateSound() {
        String string = this.getScriptItem().getSoundByID("Deactivate");
        if (string != null) {
            this.playSoundOnPlayer(string);
        }
    }

    public void playActivateDeactivateSound() {
        if (this.isActivated()) {
            this.playActivateSound();
        } else {
            this.playDeactivateSound();
        }
    }

    protected void playSoundOnPlayer(String string) {
        IsoPlayer player = this.getOwnerPlayer(this.getContainer());
        if (player != null && player.isLocalPlayer()) {
            player.getEmitter().playSound(string);
        }
    }

    protected IsoPlayer getOwnerPlayer(ItemContainer containerx) {
        if (containerx == null) {
            return null;
        } else {
            IsoObject object = containerx.getParent();
            return object instanceof IsoPlayer ? (IsoPlayer)object : null;
        }
    }

    public boolean is(ItemKey... itemKeys) {
        String string = this.getFullType();

        for (int int0 = 0; int0 < itemKeys.length; int0++) {
            if (itemKeys[int0].toString().equals(string)) {
                return true;
            }
        }

        return false;
    }

    public String getFullType() {
        assert this.fullType != null && this.fullType.equals(this.module + "." + this.type);

        return this.fullType;
    }

    public void save(ByteBuffer output, boolean net) throws IOException {
        net = false;
        if (GameWindow.DEBUG_SAVE) {
            DebugLog.log(this.getFullType());
        }

        output.putShort(this.getRegistry_id());
        output.put((byte)this.getSaveType());
        output.putInt(this.id);
        BitHeaderWrite bitHeaderWrite0 = BitHeader.allocWrite(BitHeader.HeaderSize.Byte, output);
        if (this.getCurrentUses() != 1) {
            bitHeaderWrite0.addFlags(1);
            output.putInt(this.getCurrentUses());
        }

        if (this.Condition != this.ConditionMax) {
            bitHeaderWrite0.addFlags(4);
            output.put((byte)this.getCondition());
        }

        if (this.visual != null) {
            bitHeaderWrite0.addFlags(8);
            this.visual.save(output);
        }

        if (this.isCustomColor() && (this.col.r != 1.0F || this.col.g != 1.0F || this.col.b != 1.0F || this.col.a != 1.0F)) {
            bitHeaderWrite0.addFlags(16);
            output.put(Bits.packFloatUnitToByte(this.getColor().r));
            output.put(Bits.packFloatUnitToByte(this.getColor().g));
            output.put(Bits.packFloatUnitToByte(this.getColor().b));
            output.put(Bits.packFloatUnitToByte(this.getColor().a));
        }

        if (this.itemCapacity != -1.0F) {
            bitHeaderWrite0.addFlags(32);
            output.putFloat(this.itemCapacity);
        }

        BitHeaderWrite bitHeaderWrite1 = BitHeader.allocWrite(BitHeader.HeaderSize.Integer, output);
        if (this.table != null && !this.table.isEmpty()) {
            bitHeaderWrite1.addFlags(1);
            this.table.save(output);
        }

        if (this.isActivated()) {
            bitHeaderWrite1.addFlags(2);
        }

        if (this.haveBeenRepaired != 0) {
            bitHeaderWrite1.addFlags(4);
            output.putShort((short)this.getHaveBeenRepaired());
        }

        if (this.name != null && !this.name.equals(this.originalName)) {
            bitHeaderWrite1.addFlags(8);
            GameWindow.WriteString(output, this.name);
        }

        if (this.byteData != null) {
            bitHeaderWrite1.addFlags(16);
            this.byteData.rewind();
            output.putInt(this.byteData.limit());
            output.put(this.byteData);
            this.byteData.flip();
        }

        if (this.extraItems != null && !this.extraItems.isEmpty()) {
            bitHeaderWrite1.addFlags(32);
            output.putInt(this.extraItems.size());

            for (int int0 = 0; int0 < this.extraItems.size(); int0++) {
                output.putShort(WorldDictionary.getItemRegistryID(this.extraItems.get(int0)));
            }
        }

        if (this.isCustomName()) {
            bitHeaderWrite1.addFlags(64);
        }

        if (this.isCustomWeight()) {
            bitHeaderWrite1.addFlags(128);
            output.putFloat(this.isCustomWeight() ? this.getActualWeight() : -1.0F);
        }

        if (this.keyId != -1) {
            bitHeaderWrite1.addFlags(256);
            output.putInt(this.getKeyId());
        }

        if (this.remoteControlID != -1 || this.remoteRange != 0) {
            bitHeaderWrite1.addFlags(1024);
            output.putInt(this.getRemoteControlID());
            output.putInt(this.getRemoteRange());
        }

        if (this.colorRed != 1.0F || this.colorGreen != 1.0F || this.colorBlue != 1.0F) {
            bitHeaderWrite1.addFlags(2048);
            output.put(Bits.packFloatUnitToByte(this.colorRed));
            output.put(Bits.packFloatUnitToByte(this.colorGreen));
            output.put(Bits.packFloatUnitToByte(this.colorBlue));
        }

        if (this.worker != null) {
            bitHeaderWrite1.addFlags(4096);
            GameWindow.WriteString(output, this.getWorker());
        }

        if (this.wetCooldown != -1.0F) {
            bitHeaderWrite1.addFlags(8192);
            output.putFloat(this.wetCooldown);
        }

        if (this.isFavorite()) {
            bitHeaderWrite1.addFlags(16384);
        }

        if (this.stashMap != null) {
            bitHeaderWrite1.addFlags(32768);
            GameWindow.WriteString(output, this.stashMap);
        }

        if (this.isInfected()) {
            bitHeaderWrite1.addFlags(65536);
        }

        if (this.currentAmmoCount != 0) {
            bitHeaderWrite1.addFlags(131072);
            output.putInt(this.currentAmmoCount);
        }

        if (this.attachedSlot != -1) {
            bitHeaderWrite1.addFlags(262144);
            output.putInt(this.attachedSlot);
        }

        if (this.attachedSlotType != null) {
            bitHeaderWrite1.addFlags(524288);
            GameWindow.WriteString(output, this.attachedSlotType);
        }

        if (this.attachedToModel != null) {
            bitHeaderWrite1.addFlags(1048576);
            GameWindow.WriteString(output, this.attachedToModel);
        }

        if (this.maxCapacity != -1) {
            bitHeaderWrite1.addFlags(2097152);
            output.putInt(this.maxCapacity);
        }

        if (this.isRecordedMedia()) {
            bitHeaderWrite1.addFlags(4194304);
            output.putShort(this.recordedMediaIndex);
        }

        if (this.worldScale != 1.0F) {
            bitHeaderWrite1.addFlags(16777216);
            output.putFloat(this.worldScale);
        }

        if (this.isInitialised) {
            bitHeaderWrite1.addFlags(33554432);
        }

        if (this.requiresEntitySave()) {
            bitHeaderWrite1.addFlags(67108864);
            this.saveEntity(output);
        }

        if (this.animalTracks != null) {
            bitHeaderWrite1.addFlags(134217728);
            this.animalTracks.save(output);
        }

        if (this.texture != null
            && this.texture.getName() != null
            && this.texture != Texture.getSharedTexture("media/inventory/Question_On.png")
            && this.getScriptItem().getIcon() != null
            && !Objects.equals(this.getScriptItem().getIcon(), "None")
            && !Objects.equals(this.getScriptItem().getIcon(), "default")) {
            String string0 = this.texture.getName();
            int int1 = string0.lastIndexOf(File.separator);
            if (int1 != -1) {
                string0 = string0.substring(int1 + 1).replace(".png", "");
            }

            String string1 = "Item_" + this.getScriptItem().getIcon();
            if (!Objects.equals(string0, string1)) {
                bitHeaderWrite1.addFlags(268435456);
                GameWindow.WriteString(output, this.texture.getName());
            }
        }

        if (this.modelIndex > -1) {
            bitHeaderWrite1.addFlags(536870912);
            output.putInt(this.modelIndex);
        }

        if (this.worldXRotation != 0.0F || this.worldYRotation != 0.0F || this.worldZRotation != -1.0F) {
            bitHeaderWrite1.addFlags(1073741824);
            output.putFloat(this.worldXRotation);
            output.putFloat(this.worldYRotation);
            output.putFloat(this.worldZRotation);
        }

        if (!bitHeaderWrite1.equals(0)) {
            bitHeaderWrite0.addFlags(64);
            bitHeaderWrite1.write();
        } else {
            output.position(bitHeaderWrite1.getStartPosition());
        }

        bitHeaderWrite0.write();
        bitHeaderWrite0.release();
        bitHeaderWrite1.release();
    }

    public static InventoryItem loadItem(ByteBuffer input, int WorldVersion) throws IOException {
        return loadItem(input, WorldVersion, true);
    }

    /**
     * Attempts loading the item including creation, uppon failure bytes might be skipped or the buffer position may be set to end item position.
     *  Item needs to be saved with size.
     * @return InventoryItem, or null if the item failed loading or if Creating the item failed due to being obsolete etc.
     */
    public static InventoryItem loadItem(ByteBuffer input, int WorldVersion, boolean doSaveTypeCheck) throws IOException {
        return loadItem(input, WorldVersion, doSaveTypeCheck, null);
    }

    public static InventoryItem loadItem(ByteBuffer byteBuffer, int int2, boolean boolean0, InventoryItem item1) throws IOException {
        int int0 = byteBuffer.getInt();
        if (int0 <= 0) {
            throw new IOException("InventoryItem.loadItem() invalid item data length: " + int0);
        } else {
            int int1 = byteBuffer.position();
            short short0 = byteBuffer.getShort();
            byte byte0 = -1;
            byte0 = byteBuffer.get();
            if (byte0 < 0) {
                DebugLog.log("InventoryItem.loadItem() invalid item save-type " + byte0 + ", itemtype: " + WorldDictionary.getItemTypeDebugString(short0));
                return null;
            } else {
                InventoryItem item0 = item1;
                if (item1 == null) {
                    item0 = InventoryItemFactory.CreateItem(short0);
                }

                if (boolean0 && byte0 != -1 && item0 != null && item0.getSaveType() != byte0) {
                    DebugLog.log(
                        "InventoryItem.loadItem() ignoring \"" + item0.getFullType() + "\" because type changed from " + byte0 + " to " + item0.getSaveType()
                    );
                    item0 = null;
                }

                if (item0 != null) {
                    try {
                        item0.load(byteBuffer, int2);
                    } catch (Exception exception) {
                        ExceptionLogger.logException(exception);
                        item0 = null;
                    }
                }

                if (item0 != null) {
                    if (int0 != -1 && byteBuffer.position() != int1 + int0) {
                        byteBuffer.position(int1 + int0);
                        DebugLog.log(
                            "InventoryItem.loadItem() data length not matching, resetting buffer position to '"
                                + (int1 + int0)
                                + "'. itemtype: "
                                + WorldDictionary.getItemTypeDebugString(short0)
                        );
                        if (Core.bDebug) {
                            throw new IOException(
                                "InventoryItem.loadItem() read more data than save() wrote (" + WorldDictionary.getItemTypeDebugString(short0) + ")"
                            );
                        }
                    }

                    return item0;
                } else {
                    if (byteBuffer.position() >= int1 + int0) {
                        if (byteBuffer.position() >= int1 + int0) {
                            byteBuffer.position(int1 + int0);
                            DebugLog.log(
                                "InventoryItem.loadItem() item == null, resetting buffer position to '"
                                    + (int1 + int0)
                                    + "'. itemtype: "
                                    + WorldDictionary.getItemTypeDebugString(short0)
                            );
                        }
                    } else {
                        while (byteBuffer.position() < int1 + int0) {
                            byteBuffer.get();
                        }

                        DebugLog.log("InventoryItem.loadItem() item == null, skipped bytes. itemtype: " + WorldDictionary.getItemTypeDebugString(short0));
                    }

                    return null;
                }
            }
        }
    }

    public void load(ByteBuffer input, int WorldVersion) throws IOException {
        this.id = input.getInt();
        BitHeaderRead bitHeaderRead0 = BitHeader.allocRead(BitHeader.HeaderSize.Byte, input);
        this.setCurrentUses(1);
        this.name = this.originalName;
        this.Condition = this.ConditionMax;
        this.customColor = false;
        this.col = Color.white;
        this.itemCapacity = -1.0F;
        this.table = null;
        this.activated = false;
        this.haveBeenRepaired = 0;
        this.customName = false;
        this.customWeight = false;
        this.keyId = -1;
        this.remoteControlID = -1;
        this.remoteRange = 0;
        this.colorRed = this.colorGreen = this.colorBlue = 1.0F;
        this.worker = null;
        this.wetCooldown = -1.0F;
        this.favorite = false;
        this.stashMap = null;
        this.zombieInfected = false;
        this.currentAmmoCount = 0;
        this.attachedSlot = -1;
        this.attachedSlotType = null;
        this.attachedToModel = null;
        this.maxCapacity = -1;
        this.recordedMediaIndex = -1;
        this.worldZRotation = -1.0F;
        this.worldScale = 1.0F;
        this.isInitialised = false;
        if (!bitHeaderRead0.equals(0)) {
            if (WorldVersion >= 220) {
                if (bitHeaderRead0.hasFlags(1)) {
                    this.setCurrentUses(input.getInt());
                }

                if (bitHeaderRead0.hasFlags(2)) {
                }
            } else {
                if (bitHeaderRead0.hasFlags(1)) {
                    short short0 = input.getShort();
                    this.setCurrentUses(short0);
                }

                if (bitHeaderRead0.hasFlags(2)) {
                    byte byte0 = input.get();
                }
            }

            if (bitHeaderRead0.hasFlags(4)) {
                this.setConditionWhileLoading(input.get());
            }

            if (bitHeaderRead0.hasFlags(8)) {
                this.visual = new ItemVisual();
                this.visual.load(input, WorldVersion);
            }

            if (bitHeaderRead0.hasFlags(16)) {
                float float0 = Bits.unpackByteToFloatUnit(input.get());
                float float1 = Bits.unpackByteToFloatUnit(input.get());
                float float2 = Bits.unpackByteToFloatUnit(input.get());
                float float3 = Bits.unpackByteToFloatUnit(input.get());
                this.setColor(new Color(float0, float1, float2, float3));
                this.setCustomColor(true);
            }

            if (bitHeaderRead0.hasFlags(32)) {
                this.itemCapacity = input.getFloat();
            }

            if (bitHeaderRead0.hasFlags(64)) {
                BitHeaderRead bitHeaderRead1 = BitHeader.allocRead(BitHeader.HeaderSize.Integer, input);
                if (bitHeaderRead1.hasFlags(1)) {
                    if (this.table == null) {
                        this.table = LuaManager.platform.newTable();
                    }

                    this.table.load(input, WorldVersion);
                }

                this.activated = bitHeaderRead1.hasFlags(2);
                if (bitHeaderRead1.hasFlags(4)) {
                    this.setHaveBeenRepaired(input.getShort());
                }

                if (bitHeaderRead1.hasFlags(8)) {
                    this.name = GameWindow.ReadString(input);
                }

                if (bitHeaderRead1.hasFlags(16)) {
                    int int0 = input.getInt();
                    this.byteData = ByteBuffer.allocate(int0);

                    for (int int1 = 0; int1 < int0; int1++) {
                        this.byteData.put(input.get());
                    }

                    this.byteData.flip();
                }

                if (bitHeaderRead1.hasFlags(32)) {
                    int int2 = input.getInt();
                    if (int2 > 0) {
                        this.extraItems = new ArrayList<>();

                        for (int int3 = 0; int3 < int2; int3++) {
                            short short1 = input.getShort();
                            String string = WorldDictionary.getItemTypeFromID(short1);
                            this.extraItems.add(string);
                        }
                    }
                }

                this.setCustomName(bitHeaderRead1.hasFlags(64));
                if (bitHeaderRead1.hasFlags(128)) {
                    float float4 = input.getFloat();
                    if (float4 >= 0.0F) {
                        this.setActualWeight(float4);
                        this.setWeight(float4);
                        this.setCustomWeight(true);
                    }
                }

                if (bitHeaderRead1.hasFlags(256)) {
                    this.setKeyId(input.getInt());
                }

                if (bitHeaderRead1.hasFlags(1024)) {
                    this.setRemoteControlID(input.getInt());
                    this.setRemoteRange(input.getInt());
                }

                if (bitHeaderRead1.hasFlags(2048)) {
                    float float5 = Bits.unpackByteToFloatUnit(input.get());
                    float float6 = Bits.unpackByteToFloatUnit(input.get());
                    float float7 = Bits.unpackByteToFloatUnit(input.get());
                    this.setColorRed(float5);
                    this.setColorGreen(float6);
                    this.setColorBlue(float7);
                    this.setColor(new Color(this.colorRed, this.colorGreen, this.colorBlue));
                }

                if (bitHeaderRead1.hasFlags(4096)) {
                    this.setWorker(GameWindow.ReadString(input));
                }

                if (bitHeaderRead1.hasFlags(8192)) {
                    this.setWetCooldown(input.getFloat());
                }

                this.setFavorite(bitHeaderRead1.hasFlags(16384));
                if (bitHeaderRead1.hasFlags(32768)) {
                    this.stashMap = GameWindow.ReadString(input);
                }

                this.setInfected(bitHeaderRead1.hasFlags(65536));
                if (bitHeaderRead1.hasFlags(131072)) {
                    this.setCurrentAmmoCount(input.getInt());
                }

                if (bitHeaderRead1.hasFlags(262144)) {
                    this.attachedSlot = input.getInt();
                }

                if (bitHeaderRead1.hasFlags(524288)) {
                    this.attachedSlotType = GameWindow.ReadString(input);
                }

                if (bitHeaderRead1.hasFlags(1048576)) {
                    this.attachedToModel = GameWindow.ReadString(input);
                }

                if (bitHeaderRead1.hasFlags(2097152)) {
                    this.maxCapacity = input.getInt();
                }

                if (bitHeaderRead1.hasFlags(4194304)) {
                    this.setRecordedMediaIndex(input.getShort());
                }

                if (WorldVersion < 232 && bitHeaderRead1.hasFlags(8388608)) {
                    this.setWorldZRotation(input.getInt());
                }

                if (bitHeaderRead1.hasFlags(16777216)) {
                    this.worldScale = input.getFloat();
                }

                this.setInitialised(bitHeaderRead1.hasFlags(33554432));
                if (bitHeaderRead1.hasFlags(67108864)) {
                    for (int int4 = 0; int4 < this.componentSize(); int4++) {
                        GameEntityFactory.RemoveComponent(this, this.getComponentForIndex(int4));
                    }

                    this.loadEntity(input, WorldVersion);
                }

                if (bitHeaderRead1.hasFlags(134217728)) {
                    this.animalTracks = new AnimalTracks();
                    this.animalTracks.load(input, WorldVersion);
                }

                if (bitHeaderRead1.hasFlags(268435456)) {
                    this.setTexture(Texture.getSharedTexture(GameWindow.ReadStringUTF(input)));
                }

                if (bitHeaderRead1.hasFlags(536870912)) {
                    this.modelIndex = input.getInt();
                }

                if (bitHeaderRead1.hasFlags(1073741824)) {
                    if (WorldVersion >= 232) {
                        this.setWorldXRotation(input.getFloat());
                        this.setWorldYRotation(input.getFloat());
                        this.setWorldZRotation(input.getFloat());
                    } else {
                        this.setWorldYRotation(input.getInt());
                        this.setWorldXRotation(input.getInt());
                    }
                }

                bitHeaderRead1.release();
            }
        }

        this.synchWithVisual();
        bitHeaderRead0.release();
    }

    public InventoryItem createCloneItem() {
        if (Core.getInstance().getDebug()) {
            InventoryItem item0 = InventoryItemFactory.CreateItem(this.getFullType());

            try {
                tempBuffer.clear();
                int int0 = item0.id;
                this.save(tempBuffer, false);
                tempBuffer.rewind();
                tempBuffer.getShort();
                tempBuffer.get();
                item0.load(tempBuffer, 238);
                item0.id = int0;
            } catch (IOException iOException) {
                iOException.printStackTrace();
            }

            return item0;
        } else {
            return null;
        }
    }

    public boolean IsFood() {
        return false;
    }

    public boolean IsWeapon() {
        return false;
    }

    public boolean IsDrainable() {
        return false;
    }

    public boolean IsLiterature() {
        return false;
    }

    public boolean IsClothing() {
        return false;
    }

    public boolean IsInventoryContainer() {
        return false;
    }

    public boolean IsMap() {
        return false;
    }

    static InventoryItem LoadFromFile(DataInputStream dataInputStream) throws IOException {
        GameWindow.ReadString(dataInputStream);
        return null;
    }

    public ItemContainer getOutermostContainer() {
        if (this.container != null && !"floor".equals(this.container.type)) {
            ItemContainer containerx = this.container;

            while (
                containerx.getContainingItem() != null
                    && containerx.getContainingItem().getContainer() != null
                    && !"floor".equals(containerx.getContainingItem().getContainer().type)
            ) {
                containerx = containerx.getContainingItem().getContainer();
            }

            return containerx;
        } else {
            return null;
        }
    }

    public boolean isInLocalPlayerInventory() {
        if (!GameClient.bClient) {
            return false;
        } else {
            ItemContainer containerx = this.getOutermostContainer();
            if (containerx == null) {
                return false;
            } else {
                return containerx.getParent() instanceof IsoPlayer ? ((IsoPlayer)containerx.getParent()).isLocalPlayer() : false;
            }
        }
    }

    public boolean isInPlayerInventory() {
        ItemContainer containerx = this.getOutermostContainer();
        return containerx == null ? false : containerx.getParent() instanceof IsoPlayer;
    }

    public ItemReplacement getItemReplacementPrimaryHand() {
        return this.ScriptItem.replacePrimaryHand;
    }

    public ItemReplacement getItemReplacementSecondHand() {
        return this.ScriptItem.replaceSecondHand;
    }

    public ClothingItem getClothingItem() {
        if ("RightHand".equalsIgnoreCase(this.getAlternateModelName())) {
            return this.getItemReplacementPrimaryHand().clothingItem;
        } else {
            return "LeftHand".equalsIgnoreCase(this.getAlternateModelName())
                ? this.getItemReplacementSecondHand().clothingItem
                : this.ScriptItem.getClothingItemAsset();
        }
    }

    public String getAlternateModelName() {
        if (this.getContainer() != null && this.getContainer().getParent() instanceof IsoGameCharacter character) {
            if (character.getPrimaryHandItem() == this && this.getItemReplacementPrimaryHand() != null) {
                return "RightHand";
            }

            if (character.getSecondaryHandItem() == this && this.getItemReplacementSecondHand() != null) {
                return "LeftHand";
            }
        }

        return this.m_alternateModelName;
    }

    public ItemVisual getVisual() {
        ClothingItem clothingItem = this.getClothingItem();
        if (clothingItem != null && clothingItem.isReady()) {
            if (this.visual == null) {
                this.visual = new ItemVisual();
                this.visual.setItemType(this.getFullType());
                this.visual.pickUninitializedValues(clothingItem);
            }

            this.visual.setClothingItemName(clothingItem.m_Name);
            this.visual.setAlternateModelName(this.getAlternateModelName());
            return this.visual;
        } else {
            this.visual = null;
            return null;
        }
    }

    public boolean allowRandomTint() {
        ClothingItem clothingItem = this.getClothingItem();
        return clothingItem != null ? clothingItem.m_AllowRandomTint : false;
    }

    public void synchWithVisual() {
        if (this instanceof HandWeapon && ((HandWeapon)this).getWeaponSpritesByIndex() != null && this.modelIndex == -1) {
            int int0 = ((HandWeapon)this).getWeaponSpritesByIndex().size();
            this.modelIndex = Rand.Next(int0);
        } else if ((this.getStaticModelsByIndex() != null || this.getWorldStaticModelsByIndex() != null) && this.modelIndex == -1) {
            int int1 = -1;
            if (this.getStaticModelsByIndex() != null && this.getWorldStaticModelsByIndex() != null) {
                int1 = Math.max(this.getStaticModelsByIndex().size(), this.getWorldStaticModelsByIndex().size());
            } else if (this.getStaticModelsByIndex() != null && this.getWorldStaticModelsByIndex() == null) {
                int1 = this.getStaticModelsByIndex().size();
            } else {
                int1 = this.getWorldStaticModelsByIndex().size();
            }

            this.modelIndex = Rand.Next(int1);
        }

        if (this.modelIndex != -1 && this.getIconsForTexture() != null && this.getIconsForTexture().get(this.modelIndex) != null) {
            String string0 = this.getIconsForTexture().get(this.modelIndex);
            if (!StringUtils.isNullOrWhitespace(string0)) {
                this.texture = Texture.trygetTexture("Item_" + string0);
                if (this.texture == null) {
                    this.texture = Texture.getSharedTexture("media/inventory/Question_On.png");
                }
            }
        }

        if (this instanceof Clothing || this instanceof InventoryContainer) {
            ItemVisual itemVisual = this.getVisual();
            if (itemVisual != null) {
                if (this instanceof Clothing && this.getBloodClothingType() != null) {
                    BloodClothingType.calcTotalBloodLevel((Clothing)this);
                    BloodClothingType.calcTotalDirtLevel((Clothing)this);
                }

                ClothingItem clothingItem = this.getClothingItem();
                if (clothingItem.m_AllowRandomTint && !this.customColor) {
                    this.setColor(new Color(itemVisual.m_Tint.r, itemVisual.m_Tint.g, itemVisual.m_Tint.b));
                } else {
                    this.setColor(new Color(this.getColorRed(), this.getColorGreen(), this.getColorBlue()));
                }

                if ((clothingItem.m_BaseTextures.size() > 1 || itemVisual.m_TextureChoice > -1) && this.getIconsForTexture() != null) {
                    String string1 = null;
                    if (itemVisual.m_BaseTexture > -1 && this.getIconsForTexture().size() > itemVisual.m_BaseTexture) {
                        string1 = this.getIconsForTexture().get(itemVisual.m_BaseTexture);
                    } else if (itemVisual.m_TextureChoice > -1 && this.getIconsForTexture().size() > itemVisual.m_TextureChoice) {
                        string1 = this.getIconsForTexture().get(itemVisual.m_TextureChoice);
                    }

                    if (!StringUtils.isNullOrWhitespace(string1)) {
                        this.texture = Texture.trygetTexture("Item_" + string1);
                        if (this.texture == null) {
                            this.texture = Texture.getSharedTexture("media/inventory/Question_On.png");
                        }
                    }
                }
            }
        }
    }

    /**
     * @return the containerX
     */
    public int getContainerX() {
        return this.containerX;
    }

    public void setContainerX(int _containerX) {
        this.containerX = _containerX;
    }

    /**
     * @return the containerY
     */
    public int getContainerY() {
        return this.containerY;
    }

    public void setContainerY(int _containerY) {
        this.containerY = _containerY;
    }

    /**
     * @return the DisappearOnUse
     */
    public boolean isDisappearOnUse() {
        return this.getScriptItem().isDisappearOnUse();
    }

    public boolean isKeepOnDeplete() {
        return !this.getScriptItem().isDisappearOnUse();
    }

    /**
     * @return the name
     */
    public String getName() {
        return this.getName(null);
    }

    public String getName(IsoPlayer var1) {
        if (this.getFluidContainer() != null) {
            return this.getFluidContainer().getUiName();
        } else if (this.getWorldItem() != null && this.getWorldItem().getFluidContainer() != null) {
            return this.getWorldItem().getFluidUiName();
        } else if (this.getRemoteControlID() != -1) {
            return Translator.getText("IGUI_ItemNameControllerLinked", this.name);
        } else {
            String string0 = this.name;
            if (this.getMechanicType() > 0) {
                string0 = Translator.getText("IGUI_ItemNameMechanicalType", string0, Translator.getText("IGUI_VehicleType_" + this.getMechanicType()));
            }

            String string1 = "";
            if (this.isBloody()) {
                string1 = string1 + this.bloodyString + ", ";
            }

            if (this.isBroken()) {
                string1 = string1 + this.brokenString + ", ";
            } else if (this.getCondition() < this.getConditionMax() / 3.0F) {
                string1 = string1 + this.wornString + ", ";
            }

            if (!this.isBroken() && this.hasSharpness() && this.getSharpness() < 0.33333334F) {
                if (this.getSharpness() <= 0.0F) {
                    string1 = string1 + this.bluntString + ", ";
                } else {
                    string1 = string1 + this.dullString + ", ";
                }
            }

            if (this instanceof DrainableComboItem && this.getCurrentUsesFloat() <= 0.0F) {
                string1 = string1 + this.EmptyString + ", ";
            }

            if (string1.length() > 2) {
                string1 = string1.substring(0, string1.length() - 2);
            }

            string1 = string1.trim();
            return string1.isEmpty() ? string0 : Translator.getText("IGUI_ClothingNaming", string1, string0);
        }
    }

    public void setName(String _name) {
        if (_name.length() > 256) {
            _name = _name.substring(0, Math.min(_name.length(), 256));
        }

        this.name = _name;
    }

    /**
     * @return the replaceOnUse
     */
    public String getReplaceOnUse() {
        return this.replaceOnUse;
    }

    public void setReplaceOnUse(String _replaceOnUse) {
        this.replaceOnUse = _replaceOnUse;
        this.replaceOnUseFullType = StringUtils.moduleDotType(this.getModule(), _replaceOnUse);
    }

    public String getReplaceOnUseFullType() {
        return this.replaceOnUseFullType;
    }

    /**
     * @return the ConditionMax
     */
    public int getConditionMax() {
        return this.ConditionMax;
    }

    public void setConditionMax(int _ConditionMax) {
        this.ConditionMax = _ConditionMax;
    }

    /**
     * @return the rightClickContainer
     */
    public ItemContainer getRightClickContainer() {
        return this.rightClickContainer;
    }

    public void setRightClickContainer(ItemContainer _rightClickContainer) {
        this.rightClickContainer = _rightClickContainer;
    }

    /**
     * @return the swingAnim
     */
    public String getSwingAnim() {
        return this.getScriptItem().SwingAnim;
    }

    /**
     * @return the texture
     */
    public Texture getTexture() {
        return this.texture;
    }

    public Texture getIcon() {
        return this.getTexture();
    }

    public void setTexture(Texture _texture) {
        this.texture = _texture;
    }

    public void setIcon(Texture texturex) {
        this.setTexture(texturex);
    }

    /**
     * @return the texturerotten
     */
    public Texture getTexturerotten() {
        return this.texturerotten;
    }

    public void setTexturerotten(Texture _texturerotten) {
        this.texturerotten = _texturerotten;
    }

    /**
     * @return the textureCooked
     */
    public Texture getTextureCooked() {
        return this.textureCooked;
    }

    public void setTextureCooked(Texture _textureCooked) {
        this.textureCooked = _textureCooked;
    }

    /**
     * @return the textureBurnt
     */
    public Texture getTextureBurnt() {
        return this.textureBurnt;
    }

    public void setTextureBurnt(Texture _textureBurnt) {
        this.textureBurnt = _textureBurnt;
    }

    public void setType(String _type) {
        this.type = _type;
        this.fullType = this.module + "." + _type;
    }

    public void setCurrentUses(int int0) {
        this.uses = int0;
    }

    public int getCurrentUses() {
        return this.uses;
    }

    public void setCurrentUsesFrom(InventoryItem item0) {
        float float0 = (float)item0.getCurrentUses() / item0.getMaxUses();
        this.setCurrentUses((int)(float0 * this.getMaxUses()));
    }

    public int getMaxUses() {
        return 1;
    }

    public float getCurrentUsesFloat() {
        return (float)this.uses / this.getMaxUses();
    }

    /**
     * @return the uses
     */
    @Deprecated
    public int getUses() {
        return this.uses;
    }

    @Deprecated
    public void setUses(int _uses) {
        this.uses = _uses;
    }

    public void setUsesFrom(InventoryItem item1) {
        this.setUses(item1.getUses());
    }

    /**
     * @return the Age
     */
    public float getAge() {
        return this.Age;
    }

    public void setAge(float _Age) {
        this.Age = _Age;
    }

    public float getLastAged() {
        return this.LastAged;
    }

    public void setLastAged(float time) {
        this.LastAged = time;
    }

    public void updateAge() {
    }

    public void setAutoAge() {
    }

    /**
     * @return the IsCookable
     */
    public boolean isIsCookable() {
        return this.IsCookable;
    }

    /**
     * @return the IsCookable
     */
    public boolean isCookable() {
        return this.IsCookable;
    }

    public void setIsCookable(boolean _IsCookable) {
        this.IsCookable = _IsCookable;
    }

    /**
     * @return the CookingTime
     */
    public float getCookingTime() {
        return this.CookingTime;
    }

    public void setCookingTime(float _CookingTime) {
        this.CookingTime = _CookingTime;
    }

    /**
     * @return the MinutesToCook
     */
    public float getMinutesToCook() {
        return this.MinutesToCook;
    }

    public void setMinutesToCook(float _MinutesToCook) {
        this.MinutesToCook = _MinutesToCook;
    }

    /**
     * @return the MinutesToBurn
     */
    public float getMinutesToBurn() {
        return this.MinutesToBurn;
    }

    public void setMinutesToBurn(float _MinutesToBurn) {
        this.MinutesToBurn = _MinutesToBurn;
    }

    /**
     * @return the Cooked
     */
    public boolean isCooked() {
        return this.Cooked;
    }

    public void setCooked(boolean _Cooked) {
        this.Cooked = _Cooked;
    }

    /**
     * @return the Burnt
     */
    public boolean isBurnt() {
        return this.Burnt;
    }

    public void setBurnt(boolean _Burnt) {
        this.Burnt = _Burnt;
    }

    /**
     * @return the OffAge
     */
    public int getOffAge() {
        return this.OffAge;
    }

    public void setOffAge(int _OffAge) {
        this.OffAge = _OffAge;
    }

    /**
     * @return the OffAgeMax
     */
    public int getOffAgeMax() {
        return this.OffAgeMax;
    }

    public void setOffAgeMax(int _OffAgeMax) {
        this.OffAgeMax = _OffAgeMax;
    }

    /**
     * @return the Weight
     */
    public float getWeight() {
        return Math.max(this.Weight, 0.0F);
    }

    public void setWeight(float _Weight) {
        if (_Weight < 0.0F) {
            _Weight = 0.0F;
        }

        this.Weight = _Weight;
    }

    /**
     * @return the ActualWeight
     */
    public float getActualWeight() {
        return this.getDisplayName().equals(this.getFullType()) ? 0.0F : Math.max(this.ActualWeight, 0.0F);
    }

    public void setActualWeight(float _ActualWeight) {
        if (_ActualWeight < 0.0F) {
            _ActualWeight = 0.0F;
        }

        this.ActualWeight = _ActualWeight;
    }

    /**
     * @return the WorldTexture
     */
    public String getWorldTexture() {
        return this.WorldTexture;
    }

    public void setWorldTexture(String _WorldTexture) {
        this.WorldTexture = _WorldTexture;
    }

    /**
     * @return the Description
     */
    public String getDescription() {
        return this.Description;
    }

    public void setDescription(String _Description) {
        this.Description = _Description;
    }

    public void incrementCondition(int int0) {
        this.Condition += int0;
    }

    /**
     * @return the Condition
     */
    public int getCondition() {
        return this.Condition;
    }

    public void setCondition(int _Condition, boolean doSound) {
        if (!Core.bDebug || !DebugOptions.instance.Cheat.Player.UnlimitedCondition.getValue() || this.Condition <= _Condition) {
            _Condition = Math.max(0, _Condition);
            _Condition = Math.min(this.getConditionMax(), _Condition);
            if (doSound && this.Condition > 0 && _Condition <= 0) {
                this.doBreakSound();
            } else if (doSound && this.Condition > 0 && _Condition < this.Condition) {
                this.doDamagedSound();
            }

            this.Condition = _Condition;
            this.setBroken(_Condition <= 0);
        }
    }

    public void doBreakSound() {
        if (this.getBreakSound() != null && !this.getBreakSound().isEmpty() && IsoPlayer.getInstance() != null) {
            IsoPlayer.getInstance().playSound(this.getBreakSound());
        } else if (this.getDamagedSound() != null) {
            this.doDamagedSound();
        }
    }

    public void doDamagedSound() {
        if (this.getDamagedSound() != null && !this.getDamagedSound().isEmpty() && IsoPlayer.getInstance() != null) {
            IsoPlayer.getInstance().playSound(this.getDamagedSound());
        }
    }

    public void setCondition(int _Condition) {
        this.setCondition(_Condition, true);
    }

    public void setConditionNoSound(int int0) {
        this.setCondition(int0, false);
    }

    public void setConditionWhileLoading(int int0) {
        this.Condition = PZMath.clamp(int0, 0, this.getConditionMax());
        this.broken = this.Condition <= 0;
    }

    /**
     * @return the OffString
     */
    public String getOffString() {
        return this.OffString;
    }

    public void setOffString(String _OffString) {
        this.OffString = _OffString;
    }

    /**
     * @return the CookedString
     */
    public String getCookedString() {
        return this.CookedString;
    }

    public void setCookedString(String _CookedString) {
        this.CookedString = _CookedString;
    }

    /**
     * @return the UnCookedString
     */
    public String getUnCookedString() {
        return this.UnCookedString;
    }

    public void setUnCookedString(String _UnCookedString) {
        this.UnCookedString = _UnCookedString;
    }

    /**
     * @return the BurntString
     */
    public String getBurntString() {
        return this.BurntString;
    }

    public void setBurntString(String _BurntString) {
        this.BurntString = _BurntString;
    }

    /**
     * @return the module
     */
    public String getModule() {
        return this.module;
    }

    public void setModule(String _module) {
        this.module = _module;
        this.fullType = _module + "." + this.type;
    }

    /**
     * @return the AlwaysWelcomeGift
     */
    public boolean isAlwaysWelcomeGift() {
        return this.getScriptItem().isAlwaysWelcomeGift();
    }

    /**
     * @return the CanBandage
     */
    public boolean isCanBandage() {
        return this.getScriptItem().isCanBandage();
    }

    /**
     * @return the boredomChange
     */
    public float getBoredomChange() {
        return this.boredomChange;
    }

    public void setBoredomChange(float _boredomChange) {
        this.boredomChange = _boredomChange;
    }

    /**
     * @return the unhappyChange
     */
    public float getUnhappyChange() {
        return this.unhappyChange;
    }

    public void setUnhappyChange(float _unhappyChange) {
        this.unhappyChange = _unhappyChange;
    }

    /**
     * @return the stressChange
     */
    public float getStressChange() {
        return this.stressChange;
    }

    public void setStressChange(float _stressChange) {
        this.stressChange = _stressChange;
    }

    public ArrayList<String> getTags() {
        return this.ScriptItem.getTags();
    }

    public boolean hasTag(ItemTag... itemTags) {
        for (int int0 = 0; int0 < itemTags.length; int0++) {
            if (this.hasTag(itemTags[int0].toString())) {
                return true;
            }
        }

        return false;
    }

    public boolean hasTag(String tag) {
        ArrayList arrayList = this.getTags();

        for (int int0 = 0; int0 < arrayList.size(); int0++) {
            if (((String)arrayList.get(int0)).equalsIgnoreCase(tag)) {
                return true;
            }
        }

        return false;
    }

    /**
     * @return the Taken
     */
    public ArrayList<IsoObject> getTaken() {
        return this.Taken;
    }

    public void setTaken(ArrayList<IsoObject> _Taken) {
        this.Taken = _Taken;
    }

    /**
     * @return the placeDir
     */
    public IsoDirections getPlaceDir() {
        return this.placeDir;
    }

    public void setPlaceDir(IsoDirections _placeDir) {
        this.placeDir = _placeDir;
    }

    /**
     * @return the newPlaceDir
     */
    public IsoDirections getNewPlaceDir() {
        return this.newPlaceDir;
    }

    public void setNewPlaceDir(IsoDirections _newPlaceDir) {
        this.newPlaceDir = _newPlaceDir;
    }

    public void setReplaceOnUseOn(String _ReplaceOnUseOn) {
        this.ReplaceOnUseOn = _ReplaceOnUseOn;
    }

    public String getReplaceOnUseOn() {
        return this.ReplaceOnUseOn;
    }

    public String getReplaceOnUseOnString() {
        String string = this.getReplaceOnUseOn();
        if (string.split("-")[0].trim().contains("WaterSource")) {
            string = string.split("-")[1];
            if (!string.contains(".")) {
                string = this.getModule() + "." + string;
            }
        }

        return string;
    }

    public String getReplaceTypes() {
        return this.getScriptItem().getReplaceTypes();
    }

    public HashMap<String, String> getReplaceTypesMap() {
        return this.getScriptItem().getReplaceTypesMap();
    }

    public String getReplaceType(String key) {
        return this.getScriptItem().getReplaceType(key);
    }

    public boolean hasReplaceType(String key) {
        return this.getScriptItem().hasReplaceType(key);
    }

    /**
     * @return the IsWaterSource
     */
    public boolean isWaterSource() {
        return this.hasComponent(ComponentType.FluidContainer)
            && !this.getFluidContainer().isEmpty()
            && (
                this.getFluidContainer().getPrimaryFluid() == Fluid.Water
                    || this.getFluidContainer().getPrimaryFluid() == Fluid.TaintedWater
                    || this.getFluidContainer().getPrimaryFluid() == Fluid.CarbonatedWater
            );
    }

    boolean CanStackNoTemp(InventoryItem var1) {
        return false;
    }

    public void CopyModData(KahluaTable tablex) {
        this.copyModData(tablex);
    }

    public void copyModData(KahluaTable tablex) {
        if (this.table != null) {
            this.table.wipe();
        }

        if (tablex != null) {
            LuaManager.copyTable(this.getModData(), tablex);
        }
    }

    public int getCount() {
        return this.Count;
    }

    public void setCount(int count) {
        this.Count = count;
    }

    public boolean isActivated() {
        return this.activated;
    }

    public void setActivated(boolean _activated) {
        this.activated = _activated;
        if (this.canEmitLight() && GameClient.bClient && this.getEquipParent() != null) {
            if (this.getEquipParent().getPrimaryHandItem() == this) {
                this.getEquipParent().reportEvent("EventSetActivatedPrimary");
            } else if (this.getEquipParent().getSecondaryHandItem() == this) {
                this.getEquipParent().reportEvent("EventSetActivatedSecondary");
            }
        }
    }

    public void setActivatedRemote(boolean _activated) {
        this.activated = _activated;
    }

    public void setCanBeActivated(boolean activatedItem) {
        this.canBeActivated = activatedItem;
    }

    public boolean canBeActivated() {
        return this.canBeActivated;
    }

    public void setLightStrength(float _lightStrength) {
        this.lightStrength = _lightStrength;
    }

    public float getLightStrength() {
        return this.lightStrength;
    }

    public boolean isTorchCone() {
        return this.isTorchCone;
    }

    public void setTorchCone(boolean _isTorchCone) {
        this.isTorchCone = _isTorchCone;
    }

    public float getTorchDot() {
        return this.getScriptItem().torchDot;
    }

    public int getLightDistance() {
        return this.lightDistance;
    }

    public void setLightDistance(int _lightDistance) {
        this.lightDistance = _lightDistance;
    }

    public boolean canEmitLight() {
        if (this.getLightStrength() <= 0.0F) {
            return false;
        } else {
            Drainable drainable = Type.tryCastTo(this, Drainable.class);
            return drainable == null || this.getCurrentUses() > 0;
        }
    }

    public boolean isEmittingLight() {
        return !this.canEmitLight() ? false : !this.canBeActivated() || this.isActivated();
    }

    public boolean canStoreWater() {
        return this.hasComponent(ComponentType.FluidContainer);
    }

    public float getFatigueChange() {
        return this.fatigueChange;
    }

    public void setFatigueChange(float _fatigueChange) {
        this.fatigueChange = _fatigueChange;
    }

    /**
     * Return the real condition of the weapon, based on this calcul :
     *  Condition/ConditionMax * 100
     * @return float
     */
    public float getCurrentCondition() {
        return (float)this.Condition / this.ConditionMax * 100.0F;
    }

    public void setColor(Color color) {
        this.col = color;
    }

    public Color getColor() {
        return this.col;
    }

    public ColorInfo getColorInfo() {
        return new ColorInfo(this.col.getRedFloat(), this.col.getGreenFloat(), this.col.getBlueFloat(), this.col.getAlphaFloat());
    }

    public boolean isTwoHandWeapon() {
        return this.getScriptItem().TwoHandWeapon;
    }

    public String getCustomMenuOption() {
        return this.customMenuOption;
    }

    public void setCustomMenuOption(String _customMenuOption) {
        this.customMenuOption = _customMenuOption;
    }

    public void setTooltip(String _tooltip) {
        this.getModData().rawset("Tooltip", _tooltip);
        this.tooltip = _tooltip;
    }

    public String getTooltip() {
        return this.getModData().rawget("Tooltip") instanceof String string ? string : this.tooltip;
    }

    public String getDisplayCategory() {
        return this.displayCategory;
    }

    public void setDisplayCategory(String _displayCategory) {
        this.displayCategory = _displayCategory;
    }

    public int getHaveBeenRepaired() {
        return this.haveBeenRepaired;
    }

    public void setHaveBeenRepaired(int _haveBeenRepaired) {
        this.haveBeenRepaired = _haveBeenRepaired;
    }

    public int getTimesRepaired() {
        return this.haveBeenRepaired;
    }

    public void setTimesRepaired(int int0) {
        this.haveBeenRepaired = int0;
    }

    public void copyTimesRepairedFrom(InventoryItem item1) {
        this.setTimesRepaired(item1.getTimesRepaired());
    }

    public void copyTimesRepairedTo(InventoryItem item0) {
        item0.setTimesRepaired(this.getTimesRepaired());
    }

    public int getTimesHeadRepaired() {
        return this.attrib() != null && this.attrib().contains(Attribute.TimesHeadRepaired)
            ? this.attrib().get(Attribute.TimesHeadRepaired)
            : this.haveBeenRepaired;
    }

    public void setTimesHeadRepaired(int int0) {
        if (this.attrib() != null && this.attrib().contains(Attribute.TimesHeadRepaired)) {
            this.attrib().set(Attribute.TimesHeadRepaired, int0);
        } else {
            this.haveBeenRepaired = int0;
        }
    }

    public boolean hasTimesHeadRepaired() {
        return this.attrib() != null && this.attrib().contains(Attribute.TimesHeadRepaired);
    }

    public void copyTimesHeadRepairedFrom(InventoryItem item1) {
        this.setTimesHeadRepaired(item1.getTimesHeadRepaired());
    }

    public void copyTimesHeadRepairedTo(InventoryItem item0) {
        item0.setTimesHeadRepaired(this.getTimesHeadRepaired());
    }

    public boolean isBroken() {
        return this.broken;
    }

    public void setBroken(boolean _broken) {
        this.broken = _broken;
        if (!GameClient.bClient && _broken) {
            this.onBreak();
        }
    }

    public String getDisplayName() {
        return this.name;
    }

    public boolean isTrap() {
        return this.getScriptItem().Trap;
    }

    public void addExtraItem(ItemKey itemKey) {
        this.addExtraItem(itemKey.toString());
    }

    public void addExtraItem(String _type) {
        if (this.extraItems == null) {
            this.extraItems = new ArrayList<>();
        }

        this.extraItems.add(_type);
    }

    public boolean haveExtraItems() {
        return this.extraItems != null && !this.extraItems.isEmpty();
    }

    public ArrayList<String> getExtraItems() {
        return this.extraItems;
    }

    public float getExtraItemsWeight() {
        if (!this.haveExtraItems()) {
            return 0.0F;
        } else {
            float float0 = 0.0F;

            for (int int0 = 0; int0 < this.extraItems.size(); int0++) {
                InventoryItem item1 = InventoryItemFactory.CreateItem(this.extraItems.get(int0));
                if (item1 != null && item1.getActualWeight() > 0.0F) {
                    float0 += item1.getActualWeight();
                }
            }

            return float0 * 0.6F;
        }
    }

    public boolean isCustomName() {
        return this.customName;
    }

    public void setCustomName(boolean _customName) {
        this.customName = _customName;
    }

    public boolean isFishingLure() {
        return this.getScriptItem().FishingLure;
    }

    public void copyConditionModData(InventoryItem other) {
        if (other.hasModData()) {
            KahluaTableIterator kahluaTableIterator = other.getModData().iterator();

            while (kahluaTableIterator.advance()) {
                if (kahluaTableIterator.getKey() instanceof String && ((String)kahluaTableIterator.getKey()).startsWith("condition:")) {
                    this.getModData().rawset(kahluaTableIterator.getKey(), kahluaTableIterator.getValue());
                }
            }
        }
    }

    public void setConditionFromModData(InventoryItem other) {
        if (other.hasModData()) {
            Object object = other.getModData().rawget("condition:" + this.getType());
            if (object != null && object instanceof Double) {
                this.setConditionNoSound((int)Math.round((Double)object * this.getConditionMax()));
            }
        } else if (!this.hasTag("DontInheritCondition")) {
            this.setConditionFrom(other);
        }
    }

    public String getBreakSound() {
        return this.breakSound;
    }

    public void setBreakSound(String _breakSound) {
        this.breakSound = _breakSound;
    }

    public String getPlaceOneSound() {
        return this.getScriptItem().getPlaceOneSound();
    }

    public String getPlaceMultipleSound() {
        return this.getScriptItem().getPlaceMultipleSound();
    }

    public String getSoundByID(String ID) {
        return this.getScriptItem().getSoundByID(ID);
    }

    public void setBeingFilled(boolean v) {
        this.beingFilled = v;
    }

    public boolean isBeingFilled() {
        return this.beingFilled;
    }

    public String getFillFromDispenserSound() {
        return this.getScriptItem().getFillFromDispenserSound();
    }

    public String getFillFromLakeSound() {
        return this.getScriptItem().getFillFromLakeSound();
    }

    public String getFillFromTapSound() {
        return this.getScriptItem().getFillFromTapSound();
    }

    public String getFillFromToiletSound() {
        return this.getScriptItem().getFillFromToiletSound();
    }

    public String getPourLiquidOnGroundSound() {
        if (StringUtils.equalsIgnoreCase(this.getPourType(), "Bucket") && this.hasTag("HasMetal")) {
            return "PourLiquidOnGroundMetal";
        } else {
            return StringUtils.equalsIgnoreCase(this.getPourType(), "Pot") ? "PourLiquidOnGroundMetal" : "PourLiquidOnGround";
        }
    }

    public boolean isAlcoholic() {
        return this.alcoholic;
    }

    public void setAlcoholic(boolean _alcoholic) {
        this.alcoholic = _alcoholic;
    }

    public float getAlcoholPower() {
        return this.alcoholPower;
    }

    public void setAlcoholPower(float _alcoholPower) {
        this.alcoholPower = _alcoholPower;
    }

    public float getBandagePower() {
        return this.bandagePower;
    }

    public void setBandagePower(float _bandagePower) {
        this.bandagePower = _bandagePower;
    }

    public float getReduceInfectionPower() {
        if (this.Burnt) {
            return (int)(this.ReduceInfectionPower / 3.0F);
        } else if (this.Age >= this.OffAge && this.Age < this.OffAgeMax) {
            return (int)(this.ReduceInfectionPower / 1.3F);
        } else if (this.Age >= this.OffAgeMax) {
            return (int)(this.ReduceInfectionPower / 2.2F);
        } else {
            return this.isCooked() ? this.ReduceInfectionPower * 1.3F : this.ReduceInfectionPower;
        }
    }

    public void setReduceInfectionPower(float reduceInfectionPower) {
        this.ReduceInfectionPower = reduceInfectionPower;
    }

    public final void saveWithSize(ByteBuffer output, boolean net) throws IOException {
        int int0 = output.position();
        output.putInt(0);
        int int1 = output.position();
        this.save(output, net);
        int int2 = output.position();
        output.position(int0);
        output.putInt(int2 - int1);
        output.position(int2);
    }

    public boolean isCustomWeight() {
        return this.customWeight;
    }

    public void setCustomWeight(boolean custom) {
        this.customWeight = custom;
    }

    public float getContentsWeight() {
        if (!StringUtils.isNullOrEmpty(this.getAmmoType())) {
            Item item1 = ScriptManager.instance.FindItem(this.getAmmoType());
            if (item1 != null) {
                return item1.getActualWeight() * this.getCurrentAmmoCount();
            }
        }

        if (this.getFluidContainer() != null) {
            return this.getFluidContainer().getAmount();
        } else {
            return this.getWorldItem() != null && this.getWorldItem().hasComponent(ComponentType.FluidContainer)
                ? this.getWorldItem().getFluidContainer().getAmount()
                : 0.0F;
        }
    }

    public float getHotbarEquippedWeight() {
        return this.hasTag("LightWhenAttached")
            ? (this.getActualWeight() + this.getContentsWeight()) * 0.3F
            : (this.getActualWeight() + this.getContentsWeight()) * 0.7F;
    }

    public float getEquippedWeight() {
        return (this.getActualWeight() + this.getContentsWeight()) * 0.3F;
    }

    public float getUnequippedWeight() {
        return this.getActualWeight() + this.getContentsWeight();
    }

    public boolean isEquipped() {
        if (this.getContainer() == null) {
            return false;
        } else if (this.getContainer().getParent() instanceof IsoGameCharacter character) {
            return character.isEquipped(this);
        } else {
            return this.getContainer().getParent() instanceof IsoDeadBody deadBody ? deadBody.isEquipped(this) : false;
        }
    }

    public IsoGameCharacter getUser() {
        return this.getContainer() != null
                && this.getContainer().getParent() instanceof IsoGameCharacter
                && ((IsoGameCharacter)this.getContainer().getParent()).isEquipped(this)
            ? (IsoGameCharacter)this.getContainer().getParent()
            : null;
    }

    public IsoGameCharacter getOwner() {
        return this.getContainer() != null && this.getContainer().getParent() instanceof IsoGameCharacter
            ? (IsoGameCharacter)this.getContainer().getParent()
            : null;
    }

    public int getKeyId() {
        return this.keyId;
    }

    public void setKeyId(int _keyId) {
        this.keyId = _keyId;
    }

    public boolean isRemoteController() {
        return this.remoteController;
    }

    public void setRemoteController(boolean _remoteController) {
        this.remoteController = _remoteController;
    }

    public boolean canBeRemote() {
        return this.canBeRemote;
    }

    public void setCanBeRemote(boolean _canBeRemote) {
        this.canBeRemote = _canBeRemote;
    }

    public int getRemoteControlID() {
        return this.remoteControlID;
    }

    public void setRemoteControlID(int _remoteControlID) {
        this.remoteControlID = _remoteControlID;
    }

    public int getRemoteRange() {
        return this.remoteRange;
    }

    public void setRemoteRange(int _remoteRange) {
        this.remoteRange = _remoteRange;
    }

    public String getExplosionSound() {
        return this.explosionSound;
    }

    public void setExplosionSound(String _explosionSound) {
        this.explosionSound = _explosionSound;
    }

    public String getCountDownSound() {
        return this.countDownSound;
    }

    public void setCountDownSound(String sound) {
        this.countDownSound = sound;
    }

    public float getColorRed() {
        return this.colorRed;
    }

    public void setColorRed(float _colorRed) {
        this.colorRed = _colorRed;
    }

    public float getColorGreen() {
        return this.colorGreen;
    }

    public void setColorGreen(float _colorGreen) {
        this.colorGreen = _colorGreen;
    }

    public float getColorBlue() {
        return this.colorBlue;
    }

    public void setColorBlue(float _colorBlue) {
        this.colorBlue = _colorBlue;
    }

    public String getEvolvedRecipeName() {
        return this.evolvedRecipeName;
    }

    public void setEvolvedRecipeName(String _evolvedRecipeName) {
        this.evolvedRecipeName = _evolvedRecipeName;
    }

    public float getMetalValue() {
        return this.metalValue;
    }

    public void setMetalValue(float _metalValue) {
        this.metalValue = _metalValue;
    }

    public float getItemHeat() {
        return this.itemHeat;
    }

    public void setItemHeat(float _itemHeat) {
        if (_itemHeat > 3.0F) {
            _itemHeat = 3.0F;
        }

        if (_itemHeat < 0.0F) {
            _itemHeat = 0.0F;
        }

        this.itemHeat = _itemHeat;
    }

    public float getInvHeat() {
        return 1.0F - this.itemHeat;
    }

    public float getMeltingTime() {
        return this.meltingTime;
    }

    public void setMeltingTime(float _meltingTime) {
        if (_meltingTime > 100.0F) {
            _meltingTime = 100.0F;
        }

        if (_meltingTime < 0.0F) {
            _meltingTime = 0.0F;
        }

        this.meltingTime = _meltingTime;
    }

    public String getWorker() {
        return this.worker;
    }

    public void setWorker(String _worker) {
        this.worker = _worker;
    }

    public int getID() {
        return this.id;
    }

    public void setID(int itemId) {
        this.id = itemId;
    }

    public boolean isWet() {
        return this.isWet;
    }

    public void setWet(boolean _isWet) {
        this.isWet = _isWet;
    }

    public float getWetCooldown() {
        return this.wetCooldown;
    }

    public void setWetCooldown(float _wetCooldown) {
        this.wetCooldown = _wetCooldown;
    }

    public String getItemWhenDry() {
        return this.itemWhenDry;
    }

    public void setItemWhenDry(String _itemWhenDry) {
        this.itemWhenDry = _itemWhenDry;
    }

    public boolean isFavorite() {
        return this.favorite;
    }

    public void setFavorite(boolean _favorite) {
        this.favorite = _favorite;
    }

    public ArrayList<String> getRequireInHandOrInventory() {
        return this.requireInHandOrInventory;
    }

    public void setRequireInHandOrInventory(ArrayList<String> _requireInHandOrInventory) {
        this.requireInHandOrInventory = _requireInHandOrInventory;
    }

    public boolean isCustomColor() {
        return this.customColor;
    }

    public void setCustomColor(boolean _customColor) {
        this.customColor = _customColor;
    }

    public void doBuildingStash() {
        if (this.stashMap != null) {
            if (GameClient.bClient) {
                INetworkPacket.send(PacketTypes.PacketType.ReadAnnotedMap, this.stashMap);
            } else {
                StashSystem.prepareBuildingStash(this.stashMap);
            }
        }
    }

    public void setStashMap(String _stashMap) {
        this.stashMap = _stashMap;
    }

    public String getStashMap() {
        return this.stashMap;
    }

    public int getMechanicType() {
        return this.getScriptItem().vehicleType;
    }

    public float getItemCapacity() {
        return this.itemCapacity;
    }

    public void setItemCapacity(float capacity) {
        this.itemCapacity = capacity;
    }

    public int getMaxCapacity() {
        return this.maxCapacity;
    }

    public void setMaxCapacity(int _maxCapacity) {
        this.maxCapacity = _maxCapacity;
    }

    public boolean isConditionAffectsCapacity() {
        return this.ScriptItem != null && this.ScriptItem.isConditionAffectsCapacity();
    }

    public float getBrakeForce() {
        return this.brakeForce;
    }

    public void setBrakeForce(float _brakeForce) {
        this.brakeForce = _brakeForce;
    }

    public float getDurability() {
        return this.durability;
    }

    public void setDurability(float float0) {
        this.durability = float0;
    }

    public int getChanceToSpawnDamaged() {
        return this.chanceToSpawnDamaged;
    }

    public void setChanceToSpawnDamaged(int _chanceToSpawnDamaged) {
        this.chanceToSpawnDamaged = _chanceToSpawnDamaged;
    }

    public float getConditionLowerNormal() {
        return this.conditionLowerNormal;
    }

    public void setConditionLowerNormal(float _conditionLowerNormal) {
        this.conditionLowerNormal = _conditionLowerNormal;
    }

    public float getConditionLowerOffroad() {
        return this.conditionLowerOffroad;
    }

    public void setConditionLowerOffroad(float _conditionLowerOffroad) {
        this.conditionLowerOffroad = _conditionLowerOffroad;
    }

    public float getWheelFriction() {
        return this.wheelFriction;
    }

    public void setWheelFriction(float _wheelFriction) {
        this.wheelFriction = _wheelFriction;
    }

    public float getSuspensionDamping() {
        return this.suspensionDamping;
    }

    public void setSuspensionDamping(float _suspensionDamping) {
        this.suspensionDamping = _suspensionDamping;
    }

    public float getSuspensionCompression() {
        return this.suspensionCompression;
    }

    public void setSuspensionCompression(float _suspensionCompression) {
        this.suspensionCompression = _suspensionCompression;
    }

    public void setInfected(boolean infected) {
        this.zombieInfected = infected;
    }

    public boolean isInfected() {
        return this.zombieInfected;
    }

    public float getEngineLoudness() {
        return this.engineLoudness;
    }

    public void setEngineLoudness(float _engineLoudness) {
        this.engineLoudness = _engineLoudness;
    }

    public String getStaticModel() {
        if (this.getModData().rawget("staticModel") != null) {
            return (String)this.getModData().rawget("staticModel");
        } else {
            return this.modelIndex != -1 && this.getStaticModelsByIndex() != null
                ? this.getStaticModelsByIndex().get(this.modelIndex)
                : this.getScriptItem().getStaticModel();
        }
    }

    public void setStaticModel(String string) {
        this.getModData().rawset("staticModel", string);
    }

    public void setStaticModel(ModelKey modelKey) {
        this.setStaticModel(modelKey.toString());
    }

    public String getStaticModelException() {
        return this.hasTag("UseWorldStaticModel") ? this.getWorldStaticModel() : this.getStaticModel();
    }

    public ArrayList<String> getIconsForTexture() {
        return this.iconsForTexture;
    }

    public void setIconsForTexture(ArrayList<String> _iconsForTexture) {
        this.iconsForTexture = _iconsForTexture;
    }

    public float getScore(SurvivorDesc desc) {
        return 0.0F;
    }

    /**
     * @return the previousOwner
     */
    public IsoGameCharacter getPreviousOwner() {
        return this.previousOwner;
    }

    public void setPreviousOwner(IsoGameCharacter _previousOwner) {
        this.previousOwner = _previousOwner;
    }

    /**
     * @return the ScriptItem
     */
    public Item getScriptItem() {
        return this.ScriptItem;
    }

    public void setScriptItem(Item _ScriptItem) {
        this.ScriptItem = _ScriptItem;
    }

    /**
     * @return the cat
     */
    public ItemType getCat() {
        return this.cat;
    }

    public void setCat(ItemType _cat) {
        this.cat = _cat;
    }

    /**
     * @return the container
     */
    public ItemContainer getContainer() {
        return this.container;
    }

    public void setContainer(ItemContainer _container) {
        this.container = _container;
    }

    public ArrayList<BloodClothingType> getBloodClothingType() {
        return this.bloodClothingType;
    }

    public void setBloodClothingType(ArrayList<BloodClothingType> _bloodClothingType) {
        this.bloodClothingType = _bloodClothingType;
    }

    public void setBlood(BloodBodyPartType bodyPartType, float amount) {
        ItemVisual itemVisual = this.getVisual();
        if (itemVisual != null) {
            itemVisual.setBlood(bodyPartType, amount);
        }
    }

    public float getBlood(BloodBodyPartType bodyPartType) {
        ItemVisual itemVisual = this.getVisual();
        return itemVisual != null ? itemVisual.getBlood(bodyPartType) : 0.0F;
    }

    public void setDirt(BloodBodyPartType bodyPartType, float amount) {
        ItemVisual itemVisual = this.getVisual();
        if (itemVisual != null) {
            itemVisual.setDirt(bodyPartType, amount);
        }
    }

    public float getDirt(BloodBodyPartType bodyPartType) {
        ItemVisual itemVisual = this.getVisual();
        return itemVisual != null ? itemVisual.getDirt(bodyPartType) : 0.0F;
    }

    public String getClothingItemName() {
        return this.getScriptItem().ClothingItem;
    }

    public int getStashChance() {
        return this.stashChance;
    }

    public void setStashChance(int _stashChance) {
        this.stashChance = _stashChance;
    }

    public String getEatType() {
        return this.getScriptItem().eatType;
    }

    public String getPourType() {
        return this.getScriptItem().pourType;
    }

    public boolean isUseWorldItem() {
        return this.getScriptItem().UseWorldItem;
    }

    public String getAmmoType() {
        return this.ammoType;
    }

    public void setAmmoType(String _ammoType) {
        this.ammoType = _ammoType;
    }

    public int getMaxAmmo() {
        return this.maxAmmo;
    }

    public void setMaxAmmo(int maxAmmoCount) {
        this.maxAmmo = maxAmmoCount;
    }

    public int getCurrentAmmoCount() {
        return this.currentAmmoCount;
    }

    public void setCurrentAmmoCount(int ammo) {
        this.currentAmmoCount = ammo;
    }

    public String getGunType() {
        return this.gunType;
    }

    public void setGunType(String _gunType) {
        this.gunType = _gunType;
    }

    public boolean hasBlood() {
        if (this instanceof Clothing) {
            if (this.getBloodClothingType() == null || this.getBloodClothingType().isEmpty()) {
                return false;
            }

            ArrayList arrayList = BloodClothingType.getCoveredParts(this.getBloodClothingType());
            if (arrayList == null) {
                return false;
            }

            for (int int0 = 0; int0 < arrayList.size(); int0++) {
                if (this.getBlood((BloodBodyPartType)arrayList.get(int0)) > 0.0F) {
                    return true;
                }
            }
        } else {
            if (this instanceof HandWeapon) {
                return this.getBloodLevel() > 0.0F;
            }

            if (this instanceof InventoryContainer) {
                return this.getBloodLevel() > 0.0F;
            }
        }

        return false;
    }

    public boolean hasDirt() {
        if (this instanceof Clothing) {
            if (this.getBloodClothingType() == null || this.getBloodClothingType().isEmpty()) {
                return false;
            }

            ArrayList arrayList = BloodClothingType.getCoveredParts(this.getBloodClothingType());
            if (arrayList == null) {
                return false;
            }

            for (int int0 = 0; int0 < arrayList.size(); int0++) {
                if (this.getDirt((BloodBodyPartType)arrayList.get(int0)) > 0.0F) {
                    return true;
                }
            }
        }

        return false;
    }

    public String getAttachmentType() {
        return this.attachmentType;
    }

    public void setAttachmentType(String _attachmentType) {
        this.attachmentType = _attachmentType;
    }

    public int getAttachedSlot() {
        return this.attachedSlot;
    }

    public void setAttachedSlot(int _attachedSlot) {
        this.attachedSlot = _attachedSlot;
    }

    public ArrayList<String> getAttachmentsProvided() {
        return this.attachmentsProvided;
    }

    public void setAttachmentsProvided(ArrayList<String> _attachmentsProvided) {
        this.attachmentsProvided = _attachmentsProvided;
    }

    public String getAttachedSlotType() {
        return this.attachedSlotType;
    }

    public void setAttachedSlotType(String _attachedSlotType) {
        this.attachedSlotType = _attachedSlotType;
    }

    public String getAttachmentReplacement() {
        return this.attachmentReplacement;
    }

    public void setAttachmentReplacement(String attachementReplacement) {
        this.attachmentReplacement = attachementReplacement;
    }

    public String getAttachedToModel() {
        return this.attachedToModel;
    }

    public void setAttachedToModel(String _attachedToModel) {
        this.attachedToModel = _attachedToModel;
    }

    public String getFabricType() {
        return this.getScriptItem().fabricType;
    }

    public String getStringItemType() {
        Item item0 = ScriptManager.instance.FindItem(this.getFullType());
        if (item0 != null && item0.getType() != null) {
            if (item0.getType() == Item.Type.Food) {
                return item0.CannedFood ? "CannedFood" : "Food";
            } else if ("Ammo".equals(item0.getDisplayCategory())) {
                return "Ammo";
            } else if (item0.getType() == Item.Type.Weapon && !item0.isRanged()) {
                return "MeleeWeapon";
            } else if (item0.getType() != Item.Type.WeaponPart
                && (item0.getType() != Item.Type.Weapon || !item0.isRanged())
                && (item0.getType() != Item.Type.Normal || StringUtils.isNullOrEmpty(item0.getAmmoType()))) {
                if (item0.getType() == Item.Type.Literature) {
                    return "Literature";
                } else if (item0.Medical) {
                    return "Medical";
                } else if (item0.SurvivalGear) {
                    return "SurvivalGear";
                } else {
                    return item0.MechanicsItem ? "Mechanic" : "Other";
                }
            } else {
                return "RangedWeapon";
            }
        } else {
            return "Other";
        }
    }

    public boolean isProtectFromRainWhileEquipped() {
        return this.getScriptItem().ProtectFromRainWhenEquipped;
    }

    public boolean isEquippedNoSprint() {
        return this.getScriptItem().equippedNoSprint;
    }

    public String getBodyLocation() {
        return this.getScriptItem().BodyLocation;
    }

    public String getMakeUpType() {
        return this.getScriptItem().makeUpType;
    }

    public boolean isHidden() {
        return this.getScriptItem().isHidden();
    }

    public String getConsolidateOption() {
        return this.getScriptItem().consolidateOption;
    }

    public ArrayList<String> getClothingItemExtra() {
        return this.getScriptItem().clothingItemExtra;
    }

    public ArrayList<String> getClothingItemExtraOption() {
        return this.getScriptItem().clothingItemExtraOption;
    }

    public String getWorldStaticItem() {
        if (this.getModData().rawget("Flatpack") == "true") {
            return "Flatpack";
        } else if (this.getModData().rawget("worldStaticModel") != null) {
            return (String)this.getModData().rawget("worldStaticModel");
        } else {
            String string = this.tryGetWorldStaticModelByIndex(this.getModelIndex());
            return string != null ? string : this.getScriptItem().worldStaticModel;
        }
    }

    public String getWorldStaticModel() {
        return this.getWorldStaticItem();
    }

    public void setWorldStaticItem(String string) {
        this.getModData().rawset("worldStaticModel", string);
    }

    public void setWorldStaticModel(String string) {
        this.setWorldStaticItem(string);
    }

    public void setWorldStaticModel(ModelKey modelKey) {
        this.setWorldStaticItem(modelKey.toString());
    }

    public void setRegistry_id(Item itemscript) {
        if (itemscript.getFullName().equals(this.getFullType())) {
            this.registry_id = itemscript.getRegistry_id();
        } else if (Core.bDebug) {
            WorldDictionary.DebugPrintItem(itemscript);
            throw new RuntimeException("These types should always match");
        }
    }

    public short getRegistry_id() {
        return this.registry_id;
    }

    public String getModID() {
        return this.ScriptItem != null && this.ScriptItem.getModID() != null ? this.ScriptItem.getModID() : WorldDictionary.getItemModID(this.registry_id);
    }

    public String getModName() {
        return WorldDictionary.getModNameFromID(this.getModID());
    }

    public boolean isVanilla() {
        if (this.getModID() != null) {
            return this.getModID().equals("pz-vanilla");
        } else if (Core.bDebug) {
            WorldDictionary.DebugPrintItem(this);
            throw new RuntimeException("Item has no modID?");
        } else {
            return true;
        }
    }

    public short getRecordedMediaIndex() {
        return this.recordedMediaIndex;
    }

    public void setRecordedMediaIndex(short _id) {
        this.recordedMediaIndex = _id;
        if (this.recordedMediaIndex >= 0) {
            MediaData mediaData = ZomboidRadio.getInstance().getRecordedMedia().getMediaDataFromIndex(this.recordedMediaIndex);
            this.mediaType = -1;
            if (mediaData != null) {
                this.name = mediaData.getTranslatedItemDisplayName();
                this.mediaType = mediaData.getMediaType();
            } else {
                this.recordedMediaIndex = -1;
            }
        } else {
            this.mediaType = -1;
            this.name = this.getScriptItem().getDisplayName();
        }
    }

    public void setRecordedMediaIndexInteger(int _id) {
        this.setRecordedMediaIndex((short)_id);
    }

    public boolean isRecordedMedia() {
        return this.recordedMediaIndex >= 0;
    }

    public MediaData getMediaData() {
        return this.isRecordedMedia() ? ZomboidRadio.getInstance().getRecordedMedia().getMediaDataFromIndex(this.recordedMediaIndex) : null;
    }

    public byte getMediaType() {
        return this.mediaType;
    }

    public void setMediaType(byte b) {
        this.mediaType = b;
    }

    public void setRecordedMediaData(MediaData data) {
        if (data != null && data.getIndex() >= 0) {
            this.setRecordedMediaIndex(data.getIndex());
        }
    }

    public void setWorldZRotation(float float0) {
        this.worldZRotation = float0;
    }

    public float getWorldZRotation() {
        return this.worldZRotation;
    }

    public void setWorldYRotation(float float0) {
        this.worldYRotation = float0;
    }

    public float getWorldYRotation() {
        return this.worldYRotation;
    }

    public void setWorldXRotation(float float0) {
        this.worldXRotation = float0;
    }

    public float getWorldXRotation() {
        return this.worldXRotation;
    }

    public void randomizeWorldZRotation() {
        this.worldZRotation = Rand.Next(360);
    }

    public void setWorldScale(float scale) {
        this.worldScale = scale;
    }

    public String getLuaCreate() {
        return this.getScriptItem().getLuaCreate();
    }

    public boolean isInitialised() {
        return this.isInitialised;
    }

    public void setInitialised(boolean initialised) {
        this.isInitialised = initialised;
    }

    public void initialiseItem() {
        this.setInitialised(true);
        if (this.getLuaCreate() != null) {
            Object object = LuaManager.getFunctionObject(this.getLuaCreate());
            if (object != null) {
                LuaManager.caller.protectedCallVoid(LuaManager.thread, object, this);
            }
        }
    }

    public String getMilkReplaceItem() {
        return this.getScriptItem().MilkReplaceItem;
    }

    public int getMaxMilk() {
        return this.getScriptItem().MaxMilk;
    }

    public boolean isAnimalFeed() {
        return !StringUtils.isNullOrEmpty(this.getScriptItem().AnimalFeedType);
    }

    public String getAnimalFeedType() {
        return this.getScriptItem().AnimalFeedType;
    }

    public String getDigType() {
        return this.getScriptItem().digType;
    }

    public String getSoundParameter(String parameterName) {
        return this.getScriptItem().getSoundParameter(parameterName);
    }

    public boolean isWorn() {
        return this.IsClothing() && this.isWorn();
    }

    @Override
    public void reset() {
        super.reset();
    }

    @Override
    public String toString() {
        return this.getFullType() + ":" + super.toString();
    }

    public Texture getTextureColorMask() {
        return this.textureColorMask;
    }

    public Texture getTextureFluidMask() {
        return this.textureFluidMask;
    }

    public void setTextureColorMask(String string) {
        this.textureColorMask = Texture.trygetTexture(string);
        if (this.textureColorMask == null) {
            this.textureColorMask = Texture.getSharedTexture("media/inventory/Question_On.png");
        }
    }

    public void setTextureFluidMask(String string) {
        this.textureFluidMask = Texture.trygetTexture(string);
        if (this.textureFluidMask == null) {
            this.textureFluidMask = Texture.getSharedTexture("media/inventory/Question_On.png");
        }
    }

    @Override
    public IsoGridSquare getSquare() {
        return this.equipParent != null ? this.equipParent.getSquare() : null;
    }

    @Override
    public GameEntityType getGameEntityType() {
        return GameEntityType.InventoryItem;
    }

    @Override
    public long getEntityNetID() {
        return this.id;
    }

    @Override
    public float getX() {
        return this.equipParent != null ? this.equipParent.getX() : Float.MAX_VALUE;
    }

    @Override
    public float getY() {
        return this.equipParent != null ? this.equipParent.getY() : Float.MAX_VALUE;
    }

    @Override
    public float getZ() {
        return this.equipParent != null ? this.equipParent.getZ() : Float.MAX_VALUE;
    }

    @Override
    public boolean isEntityValid() {
        return this.getEquipParent() != null;
    }

    public static boolean RemoveFromContainer(InventoryItem item) {
        ItemContainer containerx = item.getContainer();
        if (containerx != null) {
            if (containerx.getType().equals("floor") && item.getWorldItem() != null && item.getWorldItem().getSquare() != null) {
                item.getWorldItem().getSquare().transmitRemoveItemFromSquare(item.getWorldItem());
                item.getWorldItem().getSquare().getWorldObjects().remove(item.getWorldItem());
                item.getWorldItem().getSquare().getObjects().remove(item.getWorldItem());
                item.setWorldItem(null);
            }

            containerx.DoRemoveItem(item);
            return true;
        } else {
            return false;
        }
    }

    public AnimalTracks getAnimalTracks() {
        return this.animalTracks;
    }

    public void setAnimalTracks(AnimalTracks animalTracksx) {
        this.animalTracks = animalTracksx;
    }

    public void syncItemFields() {
        ItemContainer containerx = this.getOutermostContainer();
        if (containerx != null && containerx.getParent() instanceof IsoPlayer) {
            if (GameClient.bClient) {
                INetworkPacket.send(PacketTypes.PacketType.SyncItemFields, containerx.getParent(), this);
            } else if (GameServer.bServer) {
                INetworkPacket.send((IsoPlayer)containerx.getParent(), PacketTypes.PacketType.SyncItemFields, containerx.getParent(), this);
            }
        }
    }

    public String getWithDrainable() {
        return this.getScriptItem().getWithDrainable();
    }

    public String getWithoutDrainable() {
        return this.getScriptItem().getWithoutDrainable();
    }

    public ArrayList<String> getStaticModelsByIndex() {
        return this.staticModelsByIndex;
    }

    public void setStaticModelsByIndex(ArrayList<String> arrayList) {
        this.staticModelsByIndex = arrayList;
    }

    public ArrayList<String> getWorldStaticModelsByIndex() {
        return this.worldStaticModelsByIndex;
    }

    public void setWorldStaticModelsByIndex(ArrayList<String> arrayList) {
        this.worldStaticModelsByIndex = arrayList;
    }

    public String tryGetWorldStaticModelByIndex(int int0) {
        ArrayList arrayList = this.getWorldStaticModelsByIndex();
        return arrayList != null && int0 >= 0 && int0 < arrayList.size() ? (String)arrayList.get(int0) : null;
    }

    public int getModelIndex() {
        return this.modelIndex;
    }

    public void setModelIndex(int int0) {
        this.modelIndex = int0;
        this.synchWithVisual();
    }

    public float getVisionModifier() {
        return this.getScriptItem().getVisionModifier();
    }

    public float getHearingModifier() {
        return this.getScriptItem().getHearingModifier();
    }

    public String getWorldObjectSprite() {
        return this.getScriptItem().getWorldObjectSprite();
    }

    public float getStrainModifier() {
        return this.getScriptItem().getStrainModifier();
    }

    public int getConditionLowerChance() {
        return this.getScriptItem().getConditionLowerChance();
    }

    public void setConditionFrom(InventoryItem item0) {
        if (item0 != null) {
            if (this.hasSharpness() && item0.hasSharpness()) {
                this.setSharpness(item0.getSharpness());
            }

            if (this.getConditionMax() == item0.getConditionMax()) {
                this.setConditionNoSound(item0.getCondition());
            } else {
                float float0 = (float)item0.getCondition() / item0.getConditionMax();
                this.setConditionNoSound((int)(this.getConditionMax() * float0));
                this.setTimesRepaired(item0.getTimesRepaired());
            }
        }
    }

    public void setConditionTo(InventoryItem item0) {
        if (item0 != null) {
            item0.setConditionFrom(this);
        }
    }

    public void reduceCondition() {
        this.setCondition(this.getCondition() - 1);
        this.syncItemFields();
    }

    public boolean damageCheck() {
        return this.damageCheck(0, 1.0F);
    }

    public boolean damageCheck(int int0) {
        return this.damageCheck(int0, 1.0F);
    }

    public boolean damageCheck(int int0, float float0) {
        return this.damageCheck(int0, float0, true);
    }

    public boolean damageCheck(int int0, float float0, boolean boolean0) {
        return this.damageCheck(int0, float0, boolean0, true);
    }

    public boolean damageCheck(int int0, float float0, boolean boolean0, boolean boolean1) {
        return this.damageCheck(int0, float0, boolean0, boolean1, null);
    }

    public boolean damageCheck(int int0, float float0, boolean boolean0, boolean boolean1, IsoGameCharacter character) {
        float0 = Math.max(float0, 0.0F);
        if (boolean0) {
            int0 += this.getMaintenanceMod(boolean1, character);
        }

        boolean boolean2 = this.sharpnessCheck(int0 / 2, float0 / 2.0F, false, boolean1);
        if (this.headConditionCheck(int0, float0, false, boolean1)) {
            boolean2 = true;
        }

        if (Rand.NextBool((int)(this.getConditionLowerChance() * float0 + int0))) {
            this.reduceCondition();
            return true;
        } else {
            return boolean2;
        }
    }

    public boolean sharpnessCheck() {
        return this.sharpnessCheck(0);
    }

    public boolean sharpnessCheck(int int0) {
        return this.sharpnessCheck(int0, 1.0F);
    }

    public boolean sharpnessCheck(int int0, float float0) {
        return this.sharpnessCheck(int0, float0, true);
    }

    public boolean sharpnessCheck(int int0, float float0, boolean boolean0) {
        return this.sharpnessCheck(int0, float0, boolean0, true);
    }

    public boolean sharpnessCheck(int int0, float float0, boolean boolean0, boolean boolean1) {
        return this.sharpnessCheck(int0, float0, boolean0, boolean1, null);
    }

    private boolean sharpnessCheck(int int1, float float0, boolean boolean0, boolean boolean1, IsoGameCharacter character) {
        if (!this.hasSharpness()) {
            return false;
        } else {
            float0 = Math.max(float0, 0.0F);
            int int0 = 0;
            if (boolean0) {
                int0 += this.getMaintenanceMod(boolean1, character);
            }

            if (Rand.NextBool(2 * (int)(this.getConditionLowerChance() * float0 + (int1 + int0)))) {
                this.reduceSharpness();
                return true;
            } else {
                return false;
            }
        }
    }

    private void reduceSharpness() {
        if (this.hasSharpness()) {
            if (this.getSharpness() <= 0.0F) {
                if (this.hasHeadCondition()) {
                    this.reduceHeadCondition();
                } else {
                    this.reduceCondition();
                }
            } else {
                this.setSharpness(this.getSharpness() - this.getSharpnessIncrement());
            }
        }
    }

    public boolean hasSharpness() {
        return this.attrib() != null && this.attrib().getAttribute(Attribute.Sharpness) != null;
    }

    public float getSharpness() {
        if (!this.hasSharpness()) {
            return 0.0F;
        } else {
            if (this.attrib().getAttribute(Attribute.Sharpness).getFloatValue() > this.getMaxSharpness()) {
                this.applyMaxSharpness();
            }

            return this.attrib().getAttribute(Attribute.Sharpness).getFloatValue();
        }
    }

    public float getMaxSharpness() {
        if (!this.hasSharpness()) {
            return 1.0F;
        } else {
            return this.hasHeadCondition() ? (float)this.getHeadCondition() / this.getHeadConditionMax() : (float)this.getCondition() / this.getConditionMax();
        }
    }

    public void applyMaxSharpness() {
        if (this.hasSharpness()) {
            this.setSharpness(this.getMaxSharpness());
        }
    }

    public float getSharpnessMultiplier() {
        return !this.hasSharpness() ? 1.0F : (this.attrib().getAttribute(Attribute.Sharpness).getFloatValue() + 1.0F) / 2.0F;
    }

    public void setSharpness(float float1) {
        if (this.hasSharpness()) {
            float float0 = this.getMaxSharpness();
            if (float1 > float0) {
                float1 = float0;
            }

            if (float1 < 0.0F) {
                float1 = 0.0F;
            }

            if (float1 > 1.0F) {
                float1 = 1.0F;
            }

            String string = String.valueOf(float1);
            this.attrib().getAttribute(Attribute.Sharpness).setValueFromScriptString(string);
        }
    }

    public void setSharpnessFrom(InventoryItem item0) {
        if (this.hasSharpness() && item0.hasSharpness()) {
            this.setSharpness(item0.getSharpness());
        }
    }

    public float getSharpnessIncrement() {
        return !this.hasSharpness() ? 0.0F : 1.0F / this.getConditionMax();
    }

    public boolean isDamaged() {
        return this.getCondition() < this.getConditionMax();
    }

    public boolean isDull() {
        return this.hasSharpness() && this.getSharpness() <= this.getMaxSharpness() / 3.0F;
    }

    public int getMaintenanceMod() {
        return this.getMaintenanceMod(true);
    }

    public int getMaintenanceMod(boolean boolean0) {
        return this.getMaintenanceMod(boolean0, null);
    }

    public int getMaintenanceMod(IsoGameCharacter character) {
        return this.getMaintenanceMod(false, character);
    }

    public int getMaintenanceMod(boolean boolean0, IsoGameCharacter character) {
        if (boolean0 && !this.isEquipped()) {
            return 0;
        } else {
            if (boolean0 && character == null) {
                character = this.getUser();
            } else if (character == null) {
                character = this.getOwner();
            }

            if (character == null) {
                return 0;
            } else {
                int int0 = character.getPerkLevel(PerkFactory.Perks.Maintenance);
                if (this instanceof HandWeapon) {
                    int0 += character.getWeaponLevel((HandWeapon)this) / 2;
                }

                return int0;
            }
        }
    }

    public int getWeaponLevel() {
        if (this.isEquipped() && this instanceof HandWeapon weapon) {
            WeaponType weaponType = WeaponType.getWeaponType((HandWeapon)this);
            int int0 = -1;
            if (weaponType != null && weaponType != WeaponType.barehand) {
                if (weapon.getWeaponCategories().contains(WeaponCategory.AXE)) {
                    int0 = this.getUser().getPerkLevel(PerkFactory.Perks.Axe);
                }

                if (weapon.getWeaponCategories().contains(WeaponCategory.SPEAR)) {
                    int0 += this.getUser().getPerkLevel(PerkFactory.Perks.Spear);
                }

                if (weapon.getWeaponCategories().contains(WeaponCategory.SMALL_BLADE)) {
                    int0 += this.getUser().getPerkLevel(PerkFactory.Perks.SmallBlade);
                }

                if (weapon.getWeaponCategories().contains(WeaponCategory.LONG_BLADE)) {
                    int0 += this.getUser().getPerkLevel(PerkFactory.Perks.LongBlade);
                }

                if (weapon.getWeaponCategories().contains(WeaponCategory.BLUNT)) {
                    int0 += this.getUser().getPerkLevel(PerkFactory.Perks.Blunt);
                }

                if (weapon.getWeaponCategories().contains(WeaponCategory.SMALL_BLUNT)) {
                    int0 += this.getUser().getPerkLevel(PerkFactory.Perks.SmallBlunt);
                }
            }

            if (int0 > 10) {
                int0 = 10;
            }

            return int0 == -1 ? 0 : int0;
        } else {
            return 0;
        }
    }

    public boolean headConditionCheck() {
        return this.headConditionCheck(0, 1.0F);
    }

    public boolean headConditionCheck(int int0) {
        return this.headConditionCheck(int0, 1.0F);
    }

    public boolean headConditionCheck(int int0, float float0) {
        return this.headConditionCheck(int0, float0, true);
    }

    public boolean headConditionCheck(int int0, float float0, boolean boolean0) {
        return this.headConditionCheck(int0, float0, boolean0, true);
    }

    public boolean headConditionCheck(int int0, float float0, boolean boolean0, boolean boolean1) {
        return this.headConditionCheck(int0, float0, boolean0, boolean1, null);
    }

    private boolean headConditionCheck(int int1, float float0, boolean boolean0, boolean boolean1, IsoGameCharacter character) {
        if (!this.hasHeadCondition()) {
            return false;
        } else {
            float0 = Math.max(float0, 0.0F);
            int int0 = 0;
            if (boolean0) {
                int0 += this.getMaintenanceMod(boolean1, character);
            }

            if (Rand.NextBool((int)(this.getHeadConditionLowerChance() * float0 + (int1 + int0)))) {
                this.reduceHeadCondition();
                return true;
            } else {
                return false;
            }
        }
    }

    public int getHeadConditionLowerChance() {
        return (int)(this.getConditionLowerChance() * this.getHeadConditionLowerChanceMultiplier());
    }

    public float getHeadConditionLowerChanceMultiplier() {
        return this.getScriptItem().getHeadConditionLowerChanceMultiplier();
    }

    public void reduceHeadCondition() {
        if (this.hasHeadCondition()) {
            DebugLog.log("Reduce Head Condition from " + this.getHeadCondition());
            this.setHeadCondition(this.getHeadCondition() - 1);
        }
    }

    public boolean hasHeadCondition() {
        return this.attrib() != null && this.attrib().getAttribute(Attribute.HeadCondition) != null;
    }

    public int getHeadCondition() {
        return !this.hasHeadCondition() ? 0 : this.attrib().getAttribute(Attribute.HeadCondition).getIntValue();
    }

    public int getHeadConditionMax() {
        if (!this.hasHeadCondition()) {
            return 0;
        } else {
            return this.attrib() != null && this.attrib().getAttribute(Attribute.HeadConditionMax) != null
                ? this.attrib().get(Attribute.HeadConditionMax)
                : this.getConditionMax();
        }
    }

    public void setHeadCondition(int int0) {
        if (this.hasHeadCondition()) {
            if (int0 < 0) {
                int0 = 0;
            }

            int int1 = this.getHeadConditionMax();
            if (int0 > int1) {
                int0 = int1;
            }

            this.attrib().set(Attribute.HeadCondition, int0);
            if (this.getHeadCondition() <= 0) {
                this.setCondition(0);
            }
        }
    }

    public void setHeadConditionFromCondition(InventoryItem item0) {
        if (item0 != null) {
            if (this.hasHeadCondition()) {
                if (this.getHeadConditionMax() == item0.getConditionMax()) {
                    this.setHeadCondition(item0.getCondition());
                    if (this.hasSharpness() && item0.hasSharpness()) {
                        this.setSharpness(item0.getSharpness());
                    }
                } else {
                    float float0 = (float)item0.getCondition() / item0.getConditionMax();
                    this.setHeadCondition((int)(this.getHeadConditionMax() * float0));
                    if (this.hasSharpness() && item0.hasSharpness()) {
                        this.setSharpness(item0.getSharpness());
                    }
                }
            }
        }
    }

    public void setConditionFromHeadCondition(InventoryItem item0) {
        if (item0 != null) {
            if (item0.hasHeadCondition()) {
                if (this.getConditionMax() == item0.getHeadConditionMax()) {
                    this.setConditionNoSound(item0.getHeadCondition());
                    if (this.hasSharpness() && item0.hasSharpness()) {
                        this.setSharpness(item0.getSharpness());
                    }
                } else {
                    float float0 = (float)item0.getHeadCondition() / item0.getHeadConditionMax();
                    this.setConditionNoSound((int)(this.getConditionMax() * float0));
                    if (this.hasSharpness() && item0.hasSharpness()) {
                        this.setSharpness(item0.getSharpness());
                    }
                }
            }
        }
    }

    public boolean hasQuality() {
        return this.attrib() != null && this.attrib().getAttribute(Attribute.Quality) != null;
    }

    public int getQuality() {
        return !this.hasQuality() ? 0 : this.attrib().getAttribute(Attribute.Quality).getIntValue();
    }

    public void setQuality(int int0) {
        if (this.hasQuality()) {
            if (int0 < -50) {
                int0 = -50;
            }

            if (int0 > 50) {
                int0 = 50;
            }

            String string = String.valueOf(int0);
            this.attrib().getAttribute(Attribute.Quality).setValueFromScriptString(string);
        }
    }

    public String getOnBreak() {
        return this.getScriptItem().getOnBreak();
    }

    public void onBreak() {
        Object object = LuaManager.getFunctionObject(this.getOnBreak());
        IsoGameCharacter character = null;
        if (this.container != null && this.container.parent instanceof IsoGameCharacter) {
            character = (IsoGameCharacter)this.container.parent;
        }

        if (object != null) {
            LuaManager.caller.pcallvoid(LuaManager.thread, object, this, character);
        }
    }

    public float getBloodLevelAdjustedLow() {
        return !(this instanceof Clothing) && !(this instanceof InventoryContainer) ? this.getBloodLevel() : this.getBloodLevel() / 100.0F;
    }

    public float getBloodLevelAdjustedHigh() {
        return !(this instanceof Clothing) && !(this instanceof InventoryContainer) ? this.getBloodLevel() * 100.0F : this.getBloodLevel();
    }

    public float getBloodLevel() {
        return 0.0F;
    }

    public void setBloodLevel(float var1) {
    }

    public void copyBloodLevelFrom(InventoryItem item1) {
        this.setBloodLevel(item1.getBloodLevel());
    }

    public boolean isBloody() {
        return this.getBloodLevel() > 0.25F;
    }

    public String getDamagedSound() {
        return this.getScriptItem() == null ? null : this.getScriptItem().getDamagedSound();
    }

    public String getBulletHitArmourSound() {
        return this.getScriptItem() == null ? null : this.getScriptItem().getBulletHitArmourSound();
    }

    public String getWeaponHitArmourSound() {
        return this.getScriptItem() == null ? null : this.getScriptItem().getWeaponHitArmourSound();
    }

    public String getShoutType() {
        return this.getScriptItem() == null ? null : this.getScriptItem().getShoutType();
    }

    public float getShoutMultiplier() {
        return this.getScriptItem() == null ? 1.0F : this.getScriptItem().getShoutMultiplier();
    }

    public int getEatTime() {
        return this.getScriptItem() == null ? 0 : this.getScriptItem().getEatTime();
    }

    public boolean isVisualAid() {
        return this.getScriptItem().isVisualAid();
    }

    public float getDiscomfortModifier() {
        return this.getScriptItem().getDiscomfortModifier();
    }

    public boolean hasMetal() {
        return this.getMetalValue() > 0.0F || this.hasTag("HasMetal");
    }

    public float getFireFuelRatio() {
        return this.getScriptItem().getFireFuelRatio();
    }

    public float getWetness() {
        return 0.0F;
    }

    public boolean isMemento() {
        return this.hasTag("IsMemento") || Objects.equals(this.getDisplayCategory(), "Memento");
    }

    public void nameAfterDescriptor(SurvivorDesc survivorDesc) {
        if (survivorDesc != null) {
            String string = this.getScriptItem().getDisplayName();
            string = Translator.getText(string);
            this.setName(string + ": " + survivorDesc.getForename() + " " + survivorDesc.getSurname());
        }
    }

    public void monogramAfterDescriptor(SurvivorDesc survivorDesc) {
        if (survivorDesc != null) {
            String string = this.getScriptItem().getDisplayName();
            string = Translator.getText(string);
            this.setName(string + ": " + survivorDesc.getForename().charAt(0) + survivorDesc.getSurname().charAt(0));
        }
    }

    public String getLootType() {
        return ItemPickerJava.getLootType(this.getScriptItem());
    }

    public boolean getIsCraftingConsumed() {
        return this.isCraftingConsumed;
    }

    public void setIsCraftingConsumed(boolean boolean0) {
        this.isCraftingConsumed = boolean0;
    }

    public void OnAddedToContainer(ItemContainer var1) {
    }

    public void OnBeforeRemoveFromContainer(ItemContainer var1) {
    }

    public IsoDeadBody getDeadBodyObject() {
        return this.deadBodyObject;
    }

    public boolean isPureWater(boolean boolean0) {
        FluidContainer fluidContainer = this.getFluidContainerFromSelfOrWorldItem();
        if (fluidContainer != null && !fluidContainer.isEmpty()) {
            if (fluidContainer.isPureFluid(Fluid.Water)) {
                return true;
            }

            if (boolean0 && fluidContainer.isPureFluid(Fluid.TaintedWater)) {
                return true;
            }
        }

        return false;
    }

    public void copyClothing(InventoryItem item0) {
        if (this.getClothingItem() != null && item0.getClothingItem() != null) {
            Object object = LuaManager.getFunctionObject("copyClothingItem");
            if (object != null) {
                LuaManager.caller.pcallvoid(LuaManager.thread, object, item0, this);
            }
        }
    }

    public void inheritFoodAgeFrom(InventoryItem var1) {
    }

    public void inheritOlderFoodAge(InventoryItem var1) {
    }

    public boolean isFood() {
        return false;
    }

    public void unsealIfNotFull() {
        if (this.getFluidContainer() != null) {
            this.getFluidContainer().unsealIfNotFull();
        }
    }

    public void randomizeCondition() {
        if (!(this instanceof HandWeapon) || ((HandWeapon)this).getPhysicsObject() != null) {
            int int0 = Math.max(1, Rand.Next(this.getConditionMax() + 1));
            this.setCondition(int0, false);
        }
    }

    public void randomizeGeneralCondition() {
        this.randomizeCondition();
        this.randomizeHeadCondition();
        this.randomizeSharpness();
    }

    public void randomizeHeadCondition() {
        if (this.hasHeadCondition()) {
            int int0 = Math.max(1, Rand.Next(this.getConditionMax() + 1));
            this.setCondition(int0, false);
        }
    }

    public void randomizeSharpness() {
        if (this.hasSharpness()) {
            this.setSharpness(Rand.Next(0.0F, this.getMaxSharpness()));
        }
    }

    public FluidContainer getFluidContainerFromSelfOrWorldItem() {
        FluidContainer fluidContainer = this.getFluidContainer();
        if (fluidContainer == null && this.getWorldItem() != null) {
            fluidContainer = this.getWorldItem().getFluidContainer();
        }

        return fluidContainer;
    }

    public boolean isEmptyOfFluid() {
        return this.getFluidContainer() == null ? false : this.getFluidContainer().isEmpty();
    }

    public boolean isFullOfFluid() {
        return this.getFluidContainer() == null ? false : this.getFluidContainer().isFull();
    }

    public boolean isFluidContainer() {
        return this.getFluidContainer() != null;
    }

    public boolean isSpice() {
        return this.getScriptItem().isSpice();
    }

    public boolean isKeyRing() {
        return this.getScriptItem().getType() == Item.Type.KeyRing ? true : this.hasTag("KeyRing") && this instanceof InventoryContainer;
    }

    public boolean isFakeEquipped(IsoGameCharacter character) {
        if (!this.isInPlayerInventory()) {
            return false;
        } else if (character == null || character.getInventory() == null || !character.getInventory().contains(this)) {
            return false;
        } else {
            return this.getOutermostContainer() != this.getContainer() ? false : this.isKeyRing() || this.hasTag("FakeEquipped");
        }
    }

    public boolean isFakeEquipped() {
        if (!this.isInPlayerInventory()) {
            return false;
        } else {
            return this.getOutermostContainer() != this.getContainer() ? false : this.isKeyRing() || this.hasTag("FakeEquipped");
        }
    }

    public String getItemAfterCleaning() {
        return this.getScriptItem().getItemAfterCleaning();
    }

    public ArrayList<String> getResearchableRecipes() {
        return this.getScriptItem().getResearchableRecipes();
    }

    public ArrayList<String> getResearchableRecipes(IsoGameCharacter character) {
        return this.getScriptItem().getResearchableRecipes(character, true);
    }

    public boolean hasResearchableRecipes() {
        return this.getScriptItem().hasResearchableRecipes();
    }

    public void researchRecipes(IsoGameCharacter character) {
        if (this.getScriptItem() != null) {
            this.getScriptItem().researchRecipes(character);
        }
    }

    public boolean hasOrigin() {
        return this.attrib() != null
            && this.attrib().getAttribute(Attribute.OriginX) != null
            && this.attrib().getAttribute(Attribute.OriginY) != null
            && (this.attrib().getAttribute(Attribute.OriginX).getIntValue() != 0 || this.attrib().getAttribute(Attribute.OriginY).getIntValue() != 0);
    }

    public boolean canHaveOrigin() {
        return this.attrib() != null && this.attrib().getAttribute(Attribute.OriginX) != null && this.attrib().getAttribute(Attribute.OriginY) != null;
    }

    public boolean setOrigin(IsoGridSquare square) {
        return square != null && this.canHaveOrigin() ? this.setOrigin(square.getX(), square.getY(), square.getZ()) : false;
    }

    public boolean setOrigin(int int0, int int1) {
        return this.setOrigin(int0, int1, 0);
    }

    public boolean setOrigin(int int0, int int1, int int2) {
        if (!this.canHaveOrigin()) {
            return false;
        } else {
            this.setOriginX(int0);
            this.setOriginY(int1);
            this.setOriginZ(int2);
            return true;
        }
    }

    public void setOriginX(int int0) {
        if (this.canHaveOrigin()) {
            String string = String.valueOf(int0);
            this.attrib().getAttribute(Attribute.OriginX).setValueFromScriptString(string);
        }
    }

    public void setOriginY(int int0) {
        if (this.canHaveOrigin()) {
            String string = String.valueOf(int0);
            this.attrib().getAttribute(Attribute.OriginY).setValueFromScriptString(string);
        }
    }

    public void setOriginZ(int int0) {
        if (this.canHaveOrigin()) {
            String string = String.valueOf(int0);
            this.attrib().getAttribute(Attribute.OriginZ).setValueFromScriptString(string);
        }
    }

    public int getOriginX() {
        return !this.hasOrigin() ? 0 : this.attrib().getAttribute(Attribute.OriginX).getIntValue();
    }

    public int getOriginY() {
        return !this.hasOrigin() ? 0 : this.attrib().getAttribute(Attribute.OriginY).getIntValue();
    }

    public int getOriginZ() {
        return !this.hasOrigin() ? 0 : this.attrib().getAttribute(Attribute.OriginZ).getIntValue();
    }

    public String canBeEquipped() {
        return null;
    }

    public IsoPlayer getPlayer() {
        ItemContainer containerx = this.getOutermostContainer();
        if (containerx != null && containerx.getParent() != null && containerx.getParent() instanceof IsoPlayer) {
            return (IsoPlayer)containerx.getParent();
        } else {
            return this.getOwner() != null && this.getOwner() instanceof IsoPlayer ? (IsoPlayer)this.getOwner() : null;
        }
    }

    public float getWorldAlpha() {
        return this.worldAlpha;
    }

    public void setWorldAlpha(float float0) {
        this.worldAlpha = float0;
    }

    public void Remove() {
        ItemUser.RemoveItem(this);
    }

    public void SynchSpawn() {
        if (this.getContainer() != null) {
            LuaManager.GlobalObject.sendAddItemToContainer(this.getContainer(), this);
        }

        if (this.getWorldItem() != null) {
            this.getWorldItem().transmitCompleteItemToClients();
        }
    }

    public boolean isFavouriteRecipeInput(IsoPlayer player) {
        return this.getScriptItem() == null ? false : this.getScriptItem().isFavouriteRecipeInput(player);
    }

    public void copyConditionStatesFrom(InventoryItem item0) {
        if (item0 != null) {
            if (this.getClothingItem() != null && item0.getClothingItem() != null) {
                this.copyClothing(item0);
            } else {
                this.copyConditionModData(item0);
                this.setConditionFrom(item0);
                this.setHaveBeenRepaired(item0.getHaveBeenRepaired());
                if (this.hasHeadCondition()) {
                    this.setTimesHeadRepaired(item0.getTimesHeadRepaired());
                    this.setHeadConditionFromCondition(item0);
                }

                if (this.hasSharpness()) {
                    this.setSharpnessFrom(item0);
                }

                this.setFavorite(item0.isFavorite());
                this.copyBloodLevelFrom(item0);
            }
        }
    }

    public String getFileName() {
        return this.getScriptItem() == null ? null : this.getScriptItem().getFileName();
    }

    public void setDoingExtendedPlacement(boolean boolean0) {
        this.bDoingExtendedPlacement = boolean0;
    }

    public boolean isDoingExtendedPlacement() {
        return this.bDoingExtendedPlacement;
    }

    public boolean isNoRecipes(IsoPlayer player) {
        if (player == null) {
            return false;
        } else {
            String string = getNoRecipesModDataString();
            Object object = this.getModData().rawget(string);
            return object != null && object.equals(player.getFullName());
        }
    }

    public void setNoRecipes(IsoPlayer player, Boolean boolean0) {
        String string = getNoRecipesModDataString();
        if (boolean0) {
            this.getModData().rawset(string, player.getFullName());
        } else {
            this.getModData().rawset(string, false);
        }
    }

    public static String getNoRecipesModDataString() {
        return "itemNoRecipes";
    }

    public boolean isUnwanted(IsoPlayer player) {
        if (this.isRecordedMedia()) {
            return player.isUnwanted(this.getMediaData().getId());
        } else if (this.getModData().rawget("literatureTitle") != null) {
            return player.isUnwanted(this.getModData().rawget("literatureTitle").toString());
        } else if (this.getModData().rawget("printMedia") != null) {
            return player.isUnwanted(this.getModData().rawget("printMedia").toString());
        } else {
            return this.getModData().rawget("collectibleKey") != null
                ? player.isUnwanted(this.getModData().rawget("collectibleKey").toString())
                : this.getScriptItem().isUnwanted(player);
        }
    }

    public void setUnwanted(IsoPlayer player, boolean boolean0) {
        if (this.isRecordedMedia()) {
            player.setUnwanted(this.getMediaData().getId(), boolean0);
        } else if (this.getModData().rawget("literatureTitle") != null) {
            player.setUnwanted(this.getModData().rawget("literatureTitle").toString(), boolean0);
        } else if (this.getModData().rawget("printMedia") != null) {
            player.setUnwanted(this.getModData().rawget("printMedia").toString(), boolean0);
        } else if (this.getModData().rawget("collectibleKey") != null) {
            player.setUnwanted(this.getModData().rawget("collectibleKey").toString(), boolean0);
        } else if (this.getScriptItem() != null) {
            this.getScriptItem().setUnwanted(player, boolean0);
        }
    }

    public InventoryItem emptyLiquid() {
        if (this.getFluidContainer() != null) {
            this.getFluidContainer().Empty();
        }

        return this;
    }

    public String getOpeningRecipe() {
        return this.getScriptItem().getOpeningRecipe();
    }

    public boolean isSealed() {
        return this.getFluidContainer() != null && !this.getFluidContainer().canPlayerEmpty();
    }

    public boolean hasBeenSeen(IsoPlayer player) {
        if (!this.isRecordedMedia()) {
            return false;
        } else {
            return this.getScriptItem().getRecordedMediaCat() == "CDs"
                ? false
                : LuaManager.GlobalObject.getZomboidRadio().getRecordedMedia().hasListenedToAll(player, this.getMediaData());
        }
    }

    public boolean hasBeenHeard(IsoPlayer player) {
        if (!this.isRecordedMedia()) {
            return false;
        } else {
            return this.getScriptItem().getRecordedMediaCat() != "CDs"
                ? false
                : LuaManager.GlobalObject.getZomboidRadio().getRecordedMedia().hasListenedToAll(player, this.getMediaData());
        }
    }
}
