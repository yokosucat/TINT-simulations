using LightGraphs
using GraphPlot
using Compose
using Cairo
using Fontconfig
using DelimitedFiles
using Statistics

function ReadResult()
	file = open("Seed100_SimulationResults2.csv")
	data = readlines(file)
	LL = size(data)[1]
	simu = zeros(Int, LL)
	endtime = zeros(Int, LL)
	mor = zeros(Int, LL)
	obj = zeros(Int, LL)
	@show size(data)[1]
	for i = 1:size(data)[1]
		# parse.(Int, split(line))
		simu[i], endtime[i], mor[i], obj[i] = parse.(Int, split(data[i],","))
	end
	close(file)
	return simu, endtime, mor, obj
end


file = open("Seed100_AnalysisData.csv", "w")
println(file, "simu_num,time,neighboring_exc,fork_exc,anti-fork_rel,basic_exc,exciting_morphisms,excited_morphism,exciting_objects,excited_objects,density,ave_degree,ave_len,diameter,cluster_coef")

simu, endtime, mor, obj = ReadResult()
@show endtime

for i = 1:size(simu)[1]
	data = open("Seed100_Simulation"*string(i)*"_Data.csv")
	data_lines = readlines(data)
	println(file, string(i) *","* data_lines[2] *",0.00010101010101010101,1,1,1,1.0")
	for t = 1:endtime[i]
		@show i,t
		g = loadgraph("Seed100_Simulation"*string(i)*"_ExcitedCategory_time"*string(t)*".csv")
		# 密度
		# density = LightGraphs.density(g)
		# 平均次数
		ave_degree = mean(degree(g))
		# 次数分布
		degree_dist = degree_histogram(g)
		# 平均距離
		v_list = []
		for v = 1:10
			v_dist = gdistances(g,v)
			for n = 1:10
				if v_dist[n] <= 10 && v_dist[n] != 0
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
		println(file, string(i) *","* data_lines[t+2] *","* string(ave_degree) *","* string(ave_len) *","* string(dia) *","* string(cluster))	
		if t == endtime[i]
			for tt = 1:maximum(endtime) - endtime[i]
				println(file, string(i) *","* data_lines[t+2] *","* string(ave_degree) *","* string(ave_len) *","* string(dia) *","* string(cluster))
			end
		end
	end
	close(data)
end

close(file)