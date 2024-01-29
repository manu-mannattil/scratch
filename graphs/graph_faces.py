# -*- coding: utf-8 -*-

"""Find the faces of a graph given nodes and edges."""


import numpy as np
import matplotlib.pyplot as plt

class Graph(object):
    """Graph class with helper functions to find faces, borders, etc."""
    def __init__(self, coords, edges):
        self.coords, self.edges = coords, edges
        self.rs, self.fs, self.br = None, None, None

    def _angle(self, r):
        """Return the counter-clockwise angle of position vector r."""
        return np.arctan2(r[1], r[0]) % (2 * np.pi)

    def _area(self, face):
        """Area of a face (Shoelace formula)."""
        v = np.asarray(face)[:, 0]
        x, y = self.coords[v].T
        return 0.5 * abs(np.dot(x, np.roll(y, 1)) - np.dot(np.roll(x, 1), y))

    def rotsys(self):
        """Return the clockwise rotation system of a graph."""
        if self.rs:
            return self.rs

        rs = dict()

        # Collect vertices to form a vertex -> neighbors dictionary.
        for v1, v2 in self.edges:
            if v1 in rs:
                rs[v1].append(v2)
            else:
                rs[v1] = [v2]

            if v2 in rs:
                rs[v2].append(v1)
            else:
                rs[v2] = [v1]

        for vertex, neighbors in rs.items():
            # Fixing the current vertex as the origin, find the position vector
            # to its neighbors and find the counter-clockwise angle.
            r = self.coords[neighbors] - self.coords[vertex]
            angles = np.apply_along_axis(self._angle, 1, r)

            # Sort neighbors in descending order of the counter-clockwise
            # angle.  This is the clockwise ordering of neighbors.
            neighbors = np.asarray(neighbors, dtype=np.dtype(int))
            rs[vertex] = neighbors[np.argsort(angles)[::-1]]

        self.rs = rs
        return self.rs

    def faces(self):
        """Find faces of a given graph."""
        if self.fs:
            return self.fs

        rs = self.rotsys()

        # Build the set of arcs.
        arcs = set()
        for e in self.edges:
            arcs |= set([tuple(e), tuple(e[::-1])])

        fs = list()
        while arcs:
            e1 = arcs.pop()
            path = [e1]

            while True:
                # Get the neighbors of the current node.
                v1, v2 = path[-1]
                neighbors = rs[v2].tolist()

                # The next node is the node appearing after the previous node
                # in the clockwise ordering of the current node.
                ix = (neighbors.index(v1) + 1) % len(neighbors)
                e2 = (v2, neighbors[ix])

                if e2 == e1:
                    fs.append(path)
                    break
                else:
                    arcs -= set([e2])
                    path.append(e2)

        self.fs = fs
        return self.fs

    def border(self):
        """Find border edges of the graph."""
        # The border is the face with the largest area.
        fs = self.faces()
        ix = np.argmax([self._area(f) for f in fs])

        return fs[ix]

def plotgraph(coords, edges):
    """Plot the graph with given xy coordinates and edges."""
    plt.figure()

    for e in edges:
        x = [coords[e[0]][0], coords[e[1]][0]]
        y = [coords[e[0]][1], coords[e[1]][1]]
        plt.plot(x, y, 'ko-')
        plt.text(coords[e[0]][0], coords[e[0]][1], str(e[0]), color="black", backgroundcolor="#cccccc")

    plt.show()

# Test coords and edges.
coords = np.asarray([
    [0, 1],
    [1, 0],
    [-0.5, -1],
    [-1, 0],
    [0, 0.25],
    [0.7, -1.5],
    [0.5, -1.0],
    [0.9, -0.5] 
])

edges = np.asarray([
    [0, 1],
    [1, 2],
    [2, 3],
    [3, 0],
    [4, 0],
    [4, 3],
    [4, 1],
    [2, 5],
    [5, 6],
    [6, 7],
    [7, 1]
], dtype=int)

g = Graph(coords, edges)
print(g.faces())
plotgraph(coords, edges)
