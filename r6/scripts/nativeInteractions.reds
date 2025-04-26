native func Log(const text: script_ref<String>) -> Void

@addMethod(PlayerPuppet)
protected cb func OnNIFSceneEvent(event: ref<ActionEvent>) {}

class NativeInteractions extends ScriptableService {
    private cb func OnLoad() {
        GameInstance.GetCallbackSystem().RegisterCallback(n"Resource/PostLoad", this, n"ProcessScene")
        .AddTarget(ResourceTarget.Type(n"scnSceneResource"));
    }

    private cb func ProcessScene(event: ref<ResourceEvent>) {};
}