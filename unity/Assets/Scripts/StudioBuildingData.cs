using UnityEngine;

namespace StarStudio
{
    /// One building's placeholder spawn info. Mirrors the building list
    /// in lib/data/game_registry.dart (design doc §4.3) so the 3D lot
    /// matches the same 8 buildings the Flutter economy already knows
    /// about; `id` is the shared key between both sides.
    [System.Serializable]
    public struct BuildingSpawnInfo
    {
        public string id;
        public string displayName;
        public Vector3 position;
        public Vector3 size;
        public Color color;

        public BuildingSpawnInfo(string id, string displayName, Vector3 position, Vector3 size, Color color)
        {
            this.id = id;
            this.displayName = displayName;
            this.position = position;
            this.size = size;
            this.color = color;
        }
    }

    /// Static placeholder layout: a 4x2 grid with generous spacing so
    /// cubes never overlap regardless of their individual size.
    public static class StudioBuildingData
    {
        public static readonly BuildingSpawnInfo[] Buildings =
        {
            new BuildingSpawnInfo("producers_office", "Producer's Office",
                new Vector3(-15f, 0f, 0f), new Vector3(4f, 4f, 4f), new Color(1f, 0.78f, 0.34f)),
            new BuildingSpawnInfo("shoot_floor", "Shoot Floor",
                new Vector3(-5f, 0f, 0f), new Vector3(6f, 5f, 6f), new Color(1f, 0.42f, 0.42f)),
            new BuildingSpawnInfo("editing_bay", "Editing Bay",
                new Vector3(5f, 0f, 0f), new Vector3(4f, 4f, 4f), new Color(0.31f, 0.80f, 0.77f)),
            new BuildingSpawnInfo("music_room", "Music Room",
                new Vector3(15f, 0f, 0f), new Vector3(4f, 4f, 4f), new Color(0.83f, 0.63f, 0.32f)),
            new BuildingSpawnInfo("cast_suite", "Cast Suite",
                new Vector3(-15f, 0f, 14f), new Vector3(4f, 4f, 4f), new Color(1f, 0.42f, 0.42f)),
            new BuildingSpawnInfo("costume_room", "Costume Room",
                new Vector3(-5f, 0f, 14f), new Vector3(4f, 4f, 4f), new Color(0.31f, 0.80f, 0.77f)),
            new BuildingSpawnInfo("marketing_wing", "Marketing Wing",
                new Vector3(5f, 0f, 14f), new Vector3(5f, 4f, 5f), new Color(1f, 0.78f, 0.34f)),
            new BuildingSpawnInfo("mini_theatre", "Mini Theatre",
                new Vector3(15f, 0f, 14f), new Vector3(6f, 5f, 6f), new Color(0.83f, 0.63f, 0.32f)),
        };
    }
}
