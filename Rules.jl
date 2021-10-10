using Random
using Statistics

## 不定圏シミュレーションプログラム

# 潜在圏のデータを読み込み整理する
function MakeLatentCategory()	
	latent_file = open("latent_data.csv")
	latent_data = readlines(latent_file)
	LL = size(latent_data)[1]
	dom = zeros(Float64, LL)     # source node of links
	cod = zeros(Float64, LL)     # target node of links 
	prb = zeros(Float64, LL)
	exc = zeros(Int, LL)
	@show size(latent_data)[1]
	for i = 1:size(latent_data)[1]
		# parse.(Int, split(line))
		d,c,p = parse.(Float64, split(latent_data[i],","))
		# b = latent_category(c,d,f)
		dom[i] = d
		cod[i] = c
		prb[i] = p
	end
	close(latent_file)
	return dom, cod, prb, exc
end

function exciting_object(total_obj, exc_obj, obj)
	switch = true
	for i = 1:size(exc_obj)[1]
		if exc_obj[i] == obj
			switch = false
			break
		end
	end
	if switch == false
		return
	end
	for j = 1:size(total_obj)[1]
		if total_obj[j] == obj
			switch = false
			break
		end
	end
	if switch
		push!(exc_obj, obj)
	end
end

# 比喩を励起する
function metaphor_exc(source, target, dom, cod, exc, exc_obj, total_obj)
	for i = 1:size(dom)[1]
		if source == dom[i] && target == cod[i]
			exc[i] = 1
		end
	end
	push!(total_obj, source)
	push!(total_obj, target)
	push!(exc_obj, target)
end


function basic_rule(dom, cod, prb, exc, total_obj, exc_obj)
	# A→B, B→C : A→C これを探索
	# edgeをcodに持つ励起されたある射を探す
	# その間にある射を励起して記録、繰り返す
	basic_exc = 0
	for i = 1:size(dom)[1]
		if exc[i] == 1
			# dom[i]とcod[i], cod[i]を域に持つ射を探索
			for j = 1:size(dom)[1]
				if cod[i] == dom[j] && exc[j] == 1
					# cod[i]=dom[j]とcod[j]=cod[k]
					for k = 1:size(dom)[1]
						if dom[i] == dom[k] && cod[j] == cod[k] && exc[k] != 1
							exc[k] = 1
							basic_exc += 1
							exciting_object(total_obj, exc_obj, cod[k])
						end
					end
				end
			end
		end
	end
	return basic_exc
end

# objは前の時刻のexc_obj
function neighboring_rule(dom, cod, prb, exc, obj, exc_obj, total_obj)
	# objを域に持つ射を潜在圏から探す
	# 確率によって射を励起するかどうか分岐
	# 励起した射を記録、繰り返す
	# 励起した射の集合を返す
	neighboring_exc = 0
	for n = 1:size(obj)[1]
		for i = 1:size(dom)[1]
			if obj[n] == dom[i]
				# 確率で励起
				if prb[i] >= rand() && exc[i] != 1
					exc[i] = 1
					# exciting_object(total_obj, exc_obj, cod[i])
					neighboring_exc += 1
				end
			end
		end
	end
	return neighboring_exc
end

function fork_rule(dom, cod, prb, exc, obj_dom, exc_obj)
	# obj_domを域に持つ射を探索し、objに記録する
	fork_exc = 0
	anti_rel = 0
	for obj_num = 1:size(obj_dom)[1]
		obj = Float64[]
		for i = 1:size(dom)[1]
			if dom[i] == obj_dom[obj_num] && exc[i] == 1
				push!(obj, cod[i])
			end
		end
		# @show size(obj)[1]
		# 射の集合のすべての組み合わせに対して射を励起するかどうか計算
		for i = 1:size(obj)[1]
			for j = 1:size(obj)[1]
				if i == j
					continue
				end
				for k = 1:size(dom)[1]
					if obj[i] == dom[k] && obj[j] == cod[k]
						if prb[k] >= rand() && exc[k] != 1
							exc[k] = 1
							fork_exc += 1
						end
						break
					end
				end
			end
		end
		# @show reiki

		# anti-fork rule
		# obj同士の射が1つも励起されていないものを探して緩和
		for i = 1:size(obj)[1]
			relax = true
			for j = 1:size(obj)[1]
				if relax == false
					break
				end
				if i==j
					continue
				end
				for k = 1:size(exc)[1]
					if obj[i] == dom[k] && obj[j] == cod[k] && exc[k] == 1
						relax = false
						break
					end
					if obj[j] == dom[k] && obj[i] == cod[k] && exc[k] == 1
						relax = false
						break
					end
				end
			end
			if relax
				for l = 1:size(exc)[1]
					if dom[l] == obj_dom[obj_num] && cod[l] == obj[i]
						#@show dom[l], cod[l], exc[l], obj[i]
						exc[l] = 0
						anti_rel += 1
						break
					end
				end
			end
		end
	end
	return fork_exc, anti_rel
end

function save_exc_mor(time, dom, cod, exc, seed, simu)
	excited_file = open("Seed" * string(seed) * "_Simulation" * string(simu) * "_ExcitedCategory_time" * string(time) * ".csv", "w")
	println(excited_file, "10,90,d,graph,2,Int64,simplegraph")
	for i = 1:size(dom)[1]
		if exc[i] == 1
			println(excited_file, string(Int(dom[i])) * "," * string(Int(cod[i])))
		end
	end
	close(excited_file)
end

function save_exc_obj(file, time, exc_obj)
	print(file, string(time) * ",")
	for i = 1:size(exc_obj)[1] - 1
		print(file, string(exc_obj[i]) * ",")
	end
	println(file, string(exc_obj[size(exc_obj)[1]]))
end


# 励起されている射を数える
function count_exc(exc)
	#function body
	exc_num = 0
	for i = 1:size(exc)[1]
		if exc[i] == 1
			exc_num += 1
		end
	end
	return exc_num
end

# 時刻ごとの処理を行う関数
# SimulationData_seed0.csv
#  時刻ごとの励起された対象と射、励起されている対象と射の数
#  時刻、励起された対象、励起されている対象、励起された射、励起されている射
# SimulationStepsData_seed0.csv
#  時刻ごとの各ルールで励起・緩和された射の数
function time_development(dom, cod, prb, exc, seed, simu, source, target)
	limit_time = 100
	obj = Float64[]
	total_obj = Float64[]
	
	simu_file = open("Seed" * string(seed) * "_Simulation" * string(simu) * "_Data.csv", "w")
	println(simu_file, "time,neighboring_exc,fork_exc,anti-fork_rel,basic_exc,exciting_morphisms,excited_morphism,exciting_objects,excited_objects,density")
	println(simu_file, "0,0,0,0,0,1,1,2,2,0.5")
	
	excobj_file = open("Seed" * string(seed) * "_Simulation" * string(simu) * "_ExcObjData.csv", "w")
	println(excobj_file, "0" * "," * string(source) * "," * string(target))
	print(string(simu) * ": ")
	# t=0, 最初の比喩
	metaphor_exc(source, target, dom, cod, exc, obj, total_obj)
	for t = 1:limit_time
		exc_obj = Float64[]
		neigh_exc = 0
		fork_exc = 0
		fork_relax = 0
		basic_exc = 0


		print(string(t) * ", ")
		# 隣接規則のステップ
		neigh_exc = neighboring_rule(dom, cod, prb, exc, obj, exc_obj, total_obj)
		# @show size(exc_obj)[1], count_exc(exc), 
		# @show neigh_exc, exc_obj
		# 無励起
		if neigh_exc == 0
			println("Non excited morphism.")
			save_exc_mor(t, dom, cod, exc, seed, simu)
			#save_exc_obj(excobj_file, t, exc_obj)
			println(simu_file, string(t) * "," *string(neigh_exc) * "," * string(fork_exc) * "," * string(fork_relax) * "," * string(basic_exc) * "," 
			* string(neigh_exc + fork_exc - fork_relax + basic_exc) * "," * string(count_exc(exc)) * "," * string(size(exc_obj)[1]) * "," * string(size(total_obj)[1]) * "," 
			* string(count_exc(exc) / (size(total_obj)[1] * (size(total_obj)[1] - 1))))
			return t, count_exc(exc), size(total_obj)[1], 1, "non_excite"
		end

		# 分岐・非分岐規則のステップ、励起された射が1ならばスキップ
		if neigh_exc > 1
			fork_exc, fork_relax = fork_rule(dom, cod, prb, exc, obj, exc_obj)
		end
		#@show size(exc_obj)[1], count_exc(exc), 
		#@show fork_exc, fork_relax, exc_obj
		

		# 基本規則のステップ
		basic_exc = basic_rule(dom, cod, prb, exc, total_obj, exc_obj)
		#@show size(exc_obj)[1], count_exc(exc), 
		#@show basic_exc

		total_obj = vcat(total_obj, exc_obj)
		#@show total_obj

		# その時刻の顕在圏を書き出す
		save_exc_mor(t, dom, cod, exc, seed, simu)
		if size(exc_obj)[1] > 0
			save_exc_obj(excobj_file, t, exc_obj)
		end
		# 時刻、隣接励起、分岐励起、非分岐緩和、励起した射、励起した射(累計)、励起した対象、励起した対象(累計)
		println(simu_file, string(t) * "," *string(neigh_exc) * "," * string(fork_exc) * "," * string(fork_relax) * "," * string(basic_exc) * "," 
			* string(neigh_exc + fork_exc - fork_relax + basic_exc) * "," * string(count_exc(exc)) * "," * string(size(exc_obj)[1]) * "," * string(size(total_obj)[1]) * "," 
			* string(count_exc(exc) / (size(total_obj)[1] * (size(total_obj)[1] - 1))))

		if count_exc(exc) == size(exc)[1]
			println("All morphisms exciting.")
			return t, count_exc(exc), size(total_obj)[1], 3, "all_excite"
		end
		if size(exc_obj)[1] == 0
			println("All relax morphisms.")
			return t, count_exc(exc), size(total_obj)[1], 2, "all_relax"
		end
		obj = exc_obj
	end
end


# 顕在圏シミュレーター
function exc_simulator(simu_num)
	seed = 100
	source = 8
	target = 3
	dom, cod, prb, exc = MakeLatentCategory()
	Random.seed!(seed)

	time0 = open("Seed" * string(seed) * "_Simulations_ExcitedCategory_time0.csv", "w")
	println(time0, "10,90,d,graph,2,Int64,simplegraph")
	println(time0, string(source)*","*string(target))

	file = open("Seed"*string(seed)*"_SimulationResults.csv", "w")
	println(file, "simu_num,end_time,exc_mor,exc_obj,quit,quit_mes")
	for i = 1:simu_num
		exc = zeros(Int, size(dom)[1])
		endtime, exc_mor, exc_obj, exitn, message = time_development(dom, cod, prb, exc, seed, i, source, target)
		println(file, string(i)*","*string(endtime)*","*string(exc_mor)*","*string(exc_obj)*","*string(exitn)*","*string(message))
	end
	close(file)
end

#main
exc_simulator(100)