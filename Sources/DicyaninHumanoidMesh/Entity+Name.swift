import RealityKit

extension Entity {
    /// Convenience initializer that creates an entity with a name set.
    convenience init(_ name: String) {
        self.init()
        self.name = name
    }
}
