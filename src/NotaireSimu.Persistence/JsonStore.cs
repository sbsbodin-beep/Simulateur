namespace NotaireSimu.Persistence;

using System.Text.Json;
using NotaireSimu.Domain;

public static class StoragePaths
{
    public static string GetDataDir()
    {
        var docs = Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments);
        return Path.Combine(docs, AppInfo.DataFolderName);
    }

    public static string GetDataFilePath()
        => Path.Combine(GetDataDir(), AppInfo.DataFileName);
}

public static class JsonStore
{
    private static readonly JsonSerializerOptions Options = new()
    {
        WriteIndented = true
    };

    public static async Task<T> LoadOrCreateAsync<T>(Func<T> createDefault)
    {
        Directory.CreateDirectory(StoragePaths.GetDataDir());
        var path = StoragePaths.GetDataFilePath();

        if (!File.Exists(path))
        {
            var def = createDefault();
            await SaveAsync(def);
            return def;
        }

        var json = await File.ReadAllTextAsync(path);
        var obj = JsonSerializer.Deserialize<T>(json, Options);
        return obj ?? createDefault();
    }

    public static async Task SaveAsync<T>(T obj)
    {
        Directory.CreateDirectory(StoragePaths.GetDataDir());
        var path = StoragePaths.GetDataFilePath();
        var json = JsonSerializer.Serialize(obj, Options);
        await File.WriteAllTextAsync(path, json);
    }
}
