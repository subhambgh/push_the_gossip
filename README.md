# PushTheGossips
------------

To implement Gossip and Push Sum Algorithm in Elixir.

#### Group Members
------------
Subham Agrawal | UFID - 79497379
Pranav Puranik | UFID - 72038540

#### What is working
------------

- All the Topologies have been implemented for both Gossip and Push Sum algorithm. We have also implemented a failure model for both the algorithms.
- 100% convergence is being achieved for both the algorithms in all the topologies except Random 2D (in certain cases). The upper limit for the number of nodes that can be handled by the system is mostly because of the system limits on the number of processes.
- A general observation is that the topologies which is spread and has more number of connections per node will converge faster.


#### What is the largest network you managed to deal with for each type of topology and algorithm
--------------

This table will be different for every system (hardware-wise and OS-wise). It depends on how many processes can be created.

This table was created on a Windows 10 System, with 12GB RAM, Intel i5 4th Gen.

Gossip -

| Topology | Maximum Nodes |  Time for Convergence |
| ------------- | ------------- | --------- |
| Full  | 10000  | 4469 |
| Line  | 10000  | 3390 |
| Random 2D  | 2000  | 946 |
| 3D Torus  | 10000  | 10422 |
| Honeycomb  | 10000  | 14031 |
| HoneyComb Random | 8000  | 10281 |

Push Sum -

| Topology | Maximum Nodes |  Time for Convergence |
| ------------- | ------------- | --------- |
| Full  | 10000  | 3344 |
| Line  | 2000  | 24032 |
| Random 2D  | 1500  | 23203 |
| 3D Torus  | 10000 | 14844 |
| Honeycomb  | 10000  | 28922 |
| HoneyComb Random | 8000  | 27172 |

#### Steps to run
--------------

> $ ./pushthegossip numNodes topology algorithm

- numNodes - number of nodes in the topology
- topology - can be any of the following,
	- full
	- line
	- rand2D
	- 3Dtorus
	- honeycomb
	- randhoneycomb,
- algorithm can be either
	- gossip
	- push-sum


To run bonus use,
> $ ./pushthegossip numNodes topology algorithm nodes_to_fail timeout

- nodes_to_fail - maximum nodes that you want to fail
- timeout - how long to wait for the program to converge.
