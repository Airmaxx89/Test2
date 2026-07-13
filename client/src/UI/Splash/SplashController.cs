using Aethermoor.Core.Bootstrap;
using Aethermoor.Core.Scenes;
using Godot;

namespace Aethermoor.UI.Splash;

/// <summary>
/// Steuert die Startszene (Marken-Splash + Ladebildschirm). Zeigt kurz das Logo, startet
/// dann den asynchronen Wechsel zur Zielszene und spiegelt den Ladefortschritt in einen
/// Balken. Bleibt sichtbar, bis der <see cref="SceneRouter"/> die Zielszene aktiviert und
/// diese Szene ersetzt.
/// </summary>
/// <remarks>
/// Der Knoten abonniert Szenen-Ladeereignisse am zentralen <see cref="EventBus"/> und meldet
/// sich in <see cref="_ExitTree"/> wieder ab, bevor der Szenenwechsel ihn freigibt — so
/// bleiben keine Handler auf einen freigegebenen Knoten zurück.
/// </remarks>
public sealed partial class SplashController : Control
{
    private const string LogCategory = "Splash";
    private const string AutoloadPath = "/root/Game";
    private const string ProgressBarUniqueName = "%LoadingBar";

    /// <summary>Zielszene, die nach dem Splash geladen wird.</summary>
    [Export] public string NextScenePath { get; set; } = "res://scenes/Morgenau.tscn";

    /// <summary>Mindestanzeigedauer des Splash in Sekunden (Markenmoment, kein Flackern).</summary>
    [Export(PropertyHint.Range, "0,5,0.1")] public float MinimumSplashSeconds { get; set; } = 1.0f;

    private GameBootstrap _game = null!;
    private ProgressBar? _progressBar;

    public override void _Ready()
    {
        _game = GetNode<GameBootstrap>(AutoloadPath);
        _progressBar = GetNodeOrNull<ProgressBar>(ProgressBarUniqueName);

        _game.Events.Subscribe<SceneLoadProgressEvent>(OnLoadProgress);
        _game.Events.Subscribe<SceneLoadFailedEvent>(OnLoadFailed);

        // Kurzer Markenmoment, danach den eigentlichen Ladevorgang anstoßen.
        SceneTreeTimer timer = GetTree().CreateTimer(MinimumSplashSeconds);
        timer.Timeout += StartLoading;
    }

    public override void _ExitTree()
    {
        _game.Events.Unsubscribe<SceneLoadProgressEvent>(OnLoadProgress);
        _game.Events.Unsubscribe<SceneLoadFailedEvent>(OnLoadFailed);
    }

    private void StartLoading() => _game.Scenes.ChangeScene(NextScenePath);

    private void OnLoadProgress(SceneLoadProgressEvent e)
    {
        if (_progressBar is not null && e.ScenePath == NextScenePath)
        {
            _progressBar.Value = e.Progress * _progressBar.MaxValue;
        }
    }

    private void OnLoadFailed(SceneLoadFailedEvent e)
    {
        _game.Logger.Error(LogCategory, $"Startladen von '{e.ScenePath}' fehlgeschlagen: {e.Reason}");
    }
}
