/// Whether the Studio tab renders the embedded-Unity 3D lot instead of
/// the 2D [StudioLotScene]. Defaults to false: the Unity path needs a
/// Unity-exported native module this repo doesn't ship (see
/// unity/README.md) and has never been run, so it stays opt-in until
/// someone actually builds and tries it on a device.
const bool kUnity3DStudioEnabled = false;
