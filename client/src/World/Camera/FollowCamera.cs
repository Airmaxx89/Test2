using Godot;
using NumericsVector2 = System.Numerics.Vector2;

namespace Aethermoor.World.Camera;

/// <summary>
/// 2D-Folgekamera, die ihrem Ziel weich nachzieht. Delegiert die eigentliche Glättung an den
/// getesteten, engine-freien <see cref="CameraFollowSolver"/> und hält die Godot-Anbindung
/// dünn.
/// </summary>
/// <remarks>
/// Die Kamera ist bewusst kein Kind des Ziels: Als Kind würde sie starr folgen und die
/// Glättung wäre wirkungslos. Als Geschwister zieht sie pro Physik-Frame ihre Position dem
/// Ziel nach.
/// </remarks>
public sealed partial class FollowCamera : Camera2D
{
    /// <summary>Pfad zum zu verfolgenden Knoten.</summary>
    [Export] public NodePath TargetPath { get; set; } = new();

    /// <summary>Glättungsrate; höher = schnelleres Nachziehen, 0 = sofort.</summary>
    [Export(PropertyHint.Range, "0,30,0.5")] public float Smoothing { get; set; } = 8f;

    private CameraFollowSolver _solver = null!;
    private Node2D? _target;

    public override void _Ready()
    {
        _solver = new CameraFollowSolver(Smoothing);
        _target = GetNodeOrNull<Node2D>(TargetPath);
        MakeCurrent();

        if (_target is not null)
        {
            GlobalPosition = _target.GlobalPosition; // ohne Anfangsruck starten
        }
    }

    public override void _PhysicsProcess(double delta)
    {
        if (_target is null)
        {
            return;
        }

        var current = new NumericsVector2(GlobalPosition.X, GlobalPosition.Y);
        var target = new NumericsVector2(_target.GlobalPosition.X, _target.GlobalPosition.Y);

        NumericsVector2 next = _solver.Step(current, target, (float)delta);
        GlobalPosition = new Vector2(next.X, next.Y);
    }
}
