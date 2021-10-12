using LightGraphs
using GraphPlot
using Compose
using Cairo
using Fontconfig
using DelimitedFiles
using Statistics


function Analysis(file, g)
	# 密度
	density = LightGraphs.density(g)
	# 平均次数
	ave_degree = mean(degree(g))
	# 次数分布
	degree_dist = degree_histogram(g)
	# 平均距離
	v_list = []
	for v = 1:10
		v_dist = gdistances(g,v)
		for n = 1:10
			if v_dist[n] <= 100 && v_dist[n] != 0
				push!(v_list, v_dist[n])
			end
		end
	end
	@show size(v_list)[1]
	ave_len = sum(v_list)/size(v_list)[1]
	dia = maximum(v_list)

	# クラスタ係数
	cluster = global_clustering_coefficient(g)
	# 出力
	println(file, string(density) *","* string(ave_degree) *","* string(ave_len) *","* string(dia) *","* string(cluster))	
end

gname = "Random25%_node10"

# g = LightGraphs.SimpleDiGraph(100, 500)
g = SimpleDiGraph(10,25)
println(g)
LightGraphs.savegraph(gname * ".csv", g)
# LightGraphs.savegraph("SimpleDiGraph2.csv", g, compress = false)

# g = barabasi_albert(100, 4)

fig = GraphPlot.gplot(g, layout = circular_layout)
Compose.draw(PNG(gname * ".png", 100cm, 100cm), fig)
degrees = degree(g)
writedlm(gname * "_Degrees.csv", degrees, ',')

file = open(gname * "_analysis_data.csv", "w")
println(file, "density,ave_degree,ave_length,diameter,cluster_coef")

Analysis(file, g)
close(file)