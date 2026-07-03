# DicyaninHumanoidMesh

Procedural humanoid 3D shape and pose system for RealityKit on visionOS and iOS.

Builds a rounded, clay-like humanoid figure from procedurally generated organic
capsule meshes assembled into a true joint hierarchy, and drives it with named
pose presets and interpolated pose transitions.

## Install

```swift
.package(url: "https://github.com/dicyanin/DicyaninHumanoidMesh", branch: "main")
```

Add `DicyaninHumanoidMesh` to your target dependencies.

## Usage

```swift
import DicyaninHumanoidMesh

// Build a posed, collidable, paintable humanoid entity.
let humanoid = HumanoidEntity.create(pose: .tPose)
content.add(humanoid)

// Change pose instantly.
HumanoidEntity.applyPose(.dabbing, to: humanoid)

// Or drive a smooth transition per frame.
let transition = PoseTransition(from: .aPose, to: .sitting, progress: t)
HumanoidEntity.applyAngles(transition.interpolatedAngles(), to: humanoid)
```

## API

- `BodyPart` — the eleven articulated segments (head, neck, torso, arms, legs).
- `HumanoidMesh` — procedural mesh, collision shape, bounds, and layout offsets per part.
- `HumanoidEntity` — assembles the joint hierarchy and applies poses.
- `PosePreset` — seventeen named poses, each exposing `jointAngles` and a `displayName`.
- `JointAngles` / `PoseTransition` — pose representation and interpolation.
- `PaintComponent` / `PaintTexture` — per-part paint metadata and blank base surface.
