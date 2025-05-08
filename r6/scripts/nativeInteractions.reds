native func Log(const text: script_ref<String>) -> Void

@addMethod(PlayerPuppet)
protected cb func OnNIFSceneEvent(event: ref<ActionEvent>) {}

class NativeInteractions extends ScriptableService {
    private cb func OnLoad() {
        GameInstance.GetCallbackSystem().RegisterCallback(n"Resource/PostLoad", this, n"ProcessScene")
        .AddTarget(ResourceTarget.Type(n"scnSceneResource"));
    }

    public func IsCustomMappin(mappin: wref<IMappin>) -> Bool {
        return false;
    }

    private cb func ProcessScene(event: ref<ResourceEvent>) {};
}

@wrapMethod(WorldMappinsContainerController)
public func CreateMappinUIProfile(mappin: wref<IMappin>, mappinVariant: gamedataMappinVariant, customData: ref<MappinControllerCustomData>) -> MappinUIProfile {
    let service = GameInstance.GetScriptableServiceContainer().GetService(n"NativeInteractions") as NativeInteractions;
    if (IsDefined(service) && service.IsCustomMappin(mappin)) {
        return MappinUIProfile.Create(r"base\\gameplay\\gui\\widgets\\mappins\\quest\\default_mappin.inkwidget", t"MappinUISpawnProfile.MediumRange", t"WorldMappinUIProfile.nif");
    }
    return wrappedMethod(mappin, mappinVariant, customData);
}