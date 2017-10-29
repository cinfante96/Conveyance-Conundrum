extends "graph.gd"

# Member variales
# Iteration variables
var i = 0
var j = 0
# Polygon variables
var triangle
var centroid_list = []
# Color variables
var orang = Color(255,0,0)
var black = Color(0,0,0)
var vertex_colors = ColorArray()
# Graph variables
var graph
var optimal_path = []
# Priority Queue variables
const INFINITY = 3.402823e+38

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	
	# Vertex colors for fanciness
	vertex_colors.append(orang)
	
	# Find the centroid of each triangle and save it 
	while (i < get_child_count()):
		
		# Iterate over all children nodes
		var child = get_child(i)
		# Get the triangle
		triangle = child.get_polygon()
		child.set_vertex_colors(vertex_colors)
		# Append the centroid to the centroids list
		centroid_list.append(findCentroidTriangle(triangle))
		i += 1
	
	# Create the edges and add it to the graph
	graph = Graph.new(centroid_list.size())
	var edges = [[0,10,1],[0,1,2],[0,1,3],[0,1,4],[4,1,5],[5,1,6],[6,1,7],[3,1,7],[3,1,8],[8,1,9]]
	i = 0
	while i < edges.size():
		graph.addConnection(edges[i])
		i += 1
	
	# Calculate the optimal path using A*
	optimal_path = A_Star(0,9,graph.getGraph())
	optimal_path.pop_front()
	
	# Replace the nodes with their respective positions in the map
	for i in range(optimal_path.size()):
		optimal_path[i] = centroid_list[optimal_path[i]]
	
	# _draw() should be drawing after the graph is made
	
	set_fixed_process(false)
	
func _fixed_process(delta):
	# Nothing do to here for now
	pass
	
# Finds the centroid of a given triangle
# tiangle : an array of points, representing the vertices of the triangle
func findCentroidTriangle(triangle):
	
	var L = triangle[0]
	var M = triangle[1]
	var N = triangle[2]
	
	return (L + M + N)/3

# Fun fuction for drawing all sorts of stuff, 
# all drawing submethods go here
func _draw():
	# Draws the centroids of the triangles
	if (!centroid_list.empty()):
		for centroid in centroid_list:
			draw_circle(centroid,5,black)
	# Draws the graph's connections
	var nodes_and_edges = graph.getGraph()
	if (!nodes_and_edges.empty()):
		i = 0
		while i < nodes_and_edges.size():
			var edges = nodes_and_edges[i]
			for edge in edges:
				draw_line(centroid_list[i],centroid_list[edge[1]],black,1)
			i += 1

# Implementation of A*, for finding 
# the optimal path between two nodes in the graph
# start : initial node
# goal : destination goal
# graph : contains a 2d array with all the current connections in the graph
func A_Star(start,goal,graph):
	# The set of nodes already evaluated
	var closedSet = []
	
	# The set of currently discovered nodes that are not evaluated yet
	# initially, only the start node is known
	var openSet = PriorityQueue.new()
	
	# For each node, which node it can be most efficiently be reached from
	# If a node can be reached from many nodes, cameFrom will eventually
	# contain the most efficient second step
	var cameFrom = []
	
	# For each node, the cost of getting from the start node to that node
	# initialized with a default value of infinity for all nodes
	var gScore = []
	var tentative_gScore
	
	# For each node, the total cost of getting from the start node to the
	# goal by passing by that node. That value is partly known, partly heuristic
	# initialized with a default value of infinity for all nodes
	var fScore = []
	
	var a = 0
	# Initialization of gScore and fScore values for all nodes
	while a < graph.size():
		gScore.append(INFINITY)
		fScore.append(INFINITY)
		cameFrom.append(null)
		a += 1
	
	# The cost of going from start to start is zero
	gScore[start] = 0
	
	# For the first node, fScore is completely heuristic
	fScore[start] = heuristic_cost_estimate(start,goal)
	
	start = [fScore[start],start]
	openSet.insert(start)
	
	# Current node
	var current

	while !openSet.empty():
		# Get the node with the highest priority in openSet (lowest fScore)
		var temp = openSet.delMin()
		current = temp[1]
		
		if current == goal:
			return reconstruct_path(cameFrom,current)
			
		# Node visited, add it to closed list
		closedSet.append(current)
		
		# Check the neighbors of our current node
		var edgeList = graph[current]
		for edge in edgeList:
			
			var weight = edge[0]
			var neighbor = edge[1]
			
			if closedSet.find(neighbor) != -1:
				continue # Ignore the neighbor which is already evaluated
			
			# Search if our node is already in the open list
			a = 1
			var found = false
			while a <= openSet.currentSize and !found: 
				if openSet.heapList[a][1] == neighbor: 
					found = true                    
				else:
					a += 1
			
			# The distance from start to a neighbor
			tentative_gScore = gScore[current] + weight
			if tentative_gScore >= gScore[neighbor]:
				continue # This is not a better path
			
			# This path is the best until now. Let's save it
			cameFrom[neighbor] = current
			gScore[neighbor] = tentative_gScore
			fScore[neighbor] = gScore[neighbor] + heuristic_cost_estimate(neighbor,goal)
			
			if !found: # New node discovered, add it to open list
				openSet.insert([fScore[neighbor],neighbor])
			
			# Reconstruct the binary heap property in case we lost it
			if !openSet.empty():
				var currentHeaplist = openSet.heapList
				currentHeaplist.pop_front()
				openSet.heapList = []
				openSet.buildHeap(currentHeaplist) 
			
	# We failed to find a path from source to goal
	return null

# Reconstructs the optimal path using 
# the pointers of each node in the list cameFrom
# cameFrom : pointers describing for each node, which node it can be most efficiently be reached from
# current : current node
func reconstruct_path(cameFrom,current):
	
	# Container for the path
	var total_path = [current]
	var x = 0
	
	# Reconstruct the path from the pointers in the list
	while x < cameFrom.size() and current != null:
		current = cameFrom[current]
		total_path.append(current)
		x += 1
		
	# Invert the path for easy printing later
	total_path.invert()
	
	return total_path

# Heuristic function to predict the optimal path
# Current heuristic in use: Euclidean Distance
# from : source node
# to : destination node
func heuristic_cost_estimate(from,to):
	
	var vector0 = centroid_list[from]
	var vector1 = centroid_list[to]
	
	var a = vector0.x - vector1.x
	var b = vector0.y - vector1.y
	
	return sqrt(pow(a,2)+pow(b,2))
	
func printPath(path):
	
	if path != null:
		for node in path:
			print(node)
	else:
		print("A* could not find a path in the graph")