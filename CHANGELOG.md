Changelog
============

This is a high-level changelog for each released versions of the plugin.
For a more detailed list of past and incoming changes, see the commit history.


0.2
----

- Complete rewrite using a node-tree approach, each node has its own parameters
- Ported to GDNative C++ for speed
- Basic leaves support
- Texturing
- Much more parameters, and some can be modulated with curves
- Jittered approach to randomization, so regular trees are also possible
- `seek_sun` parameter to bend branches up or down
- Adaptative branch geometry to reduce polycount
- Nodes can be turned on/off
- The tree can be saved as an `ArrayMesh` asset (`.mesh`)


0.1
----

- Open-sourced
- Only generates branches at random
- Only one set of parameters with multipliers for child branches
- Pure GDScript
