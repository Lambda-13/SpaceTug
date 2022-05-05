var/locks[0]
var/CPUOn = 0
var/overlayManager/OverlayManager

obj/helper
	suckable = 0
	invisibility = 101

	doorCloser
		icon = 'doorCloser.dmi'

	opacityClearer
		icon = 'clearer.dmi'

		New()
			loc:opacity = 0
			del src

world
	view = VIEW
	name = "КосмоБуксир"
	mob = /mob/player
	turf = /turf/space
	area = /area/space


	New()
		. = ..()
		SetUpIcons() //Register icon overlays
		Populate() //Add cats and critters
		spawn MaintainVacuum()
		spawn MaintainSophies() //Those blinking lights are important!
		spawn WatchForVictory()


	proc/WatchForVictory()
		while(1)
			if(checkVictory && (locks["selfdestruct"] != 1)) CheckVictory()
			sleep(11)


	proc/CheckVictory()
		if(locks["victory"]) return

		checkVictory = 0

		var/list/victors = new()

		var/critterCount = 0
		var/R
		var/V

		for(var/M as mob in world)

			if(CheckGhost(M)) continue

			var/area/A = M:loc
			if(A) A = A.loc

			if(istype(A)) R = A.realm
			else R = "none"

			V = victors[R]
			if(V == "ongoing") continue

			if(istype(M, /mob/player) && M:client)
				if(V == /mob/critter) victors[R] = "ongoing"
				else victors[R] = /mob/player
			else
				if(istype(M, /mob/critter) && M:health > 0)
					critterCount += 1
					if(V == /mob/player) victors[R] = "ongoing"
					else victors[R] = /mob/critter


		var/shipType = victors["ship"]
		var/shuttleType = victors["shuttle"]

		if(shipType == "ongoing" || shuttleType == "ongoing") return

		switch(shipType)
			if(/mob/player)
				world << "\n<b>Люди выйграли!</b>"
				spawn Recap()
			if(/mob/critter)
				world << \
					"\n<b>Монсторо возвращается на Землю с [critterCount] особью на борту. \
					Весь Ад вырвался на свободу!</b>"
				spawn Recap()
			else
				switch(shuttleType)
					if(/mob/player)
						world << \
							"\n<b>Корабль уничтожен, но некоторые люди смогли выжить \
							У Межгосударственной Торговой Комиссии будет много вопросов!</b>"
						spawn Recap()
					if(/mob/critter)
						world << \
							"\n<b>Шаттл был захвачен особью.</b>"
						spawn Recap()
					else
						world << \
							"\n<b>Тварей не осталось! Это победа Земли... \
							но не большое утешение для экипажа.</b>"
						spawn Recap()


	proc/Recap()
		locks["victory"] = 1
		if(deathCauses.len)
			world << "<p><b><u>Они были расходным материалом</u></b><br>"
			for(var/K in deathCauses)
				world << "[K]: [deathCauses[K]]"
		world << "<p>Рестарт через [REBOOT_DELAY / 10] секунд."
		sleep(REBOOT_DELAY)
		Reboot()


	proc/SetUpIcons()
		OverlayManager = new()
		OverlayManager.RegisterIcon('soot.dmi', list("1", "2", "3", "4"), TURF_LAYER + 0.5)
		OverlayManager.RegisterIcon('dirs.dmi', list("1", "2", "4", "8"))
		OverlayManager.RegisterIcon('wall5.dmi', list("a1", "a2", "a3"), TURF_LAYER + 0.1)
		OverlayManager.RegisterIcon('blip.dmi', \
			list("11", "31", "51", "13", "33", "53", "15", "35", "55"))

		OverlayManager.RegisterIcon('flasher.dmi', list("small"), TURF_LAYER + 0.2)
		//(Mobs will register their own splat overlays independently.)


	proc/Populate()
		var/i
		for(i = 1; i <= CAT_COUNT; i++)
			var/mob/cat/C = new()
			PutInPlace(C, /area/room)

		var/K
		if(!CRITTER_TYPE) //Pick random critter if world does not have a fixed type
			var/list/L = typesof(/mob/critter) - /mob/critter
			K = L[rand(1, L.len)]
		else K = CRITTER_TYPE

		for(i = 1; i <= CRITTER_COUNT; i++)
			var/mob/critter/CR = new K()
			PutInPlace(CR, /area/ventilation_shaft)


dmverb
	verb/showCPU(N as null | num)
		if(CPUOn) CPUOn = 0
		else
			CPUOn = 1
			ShowCPU(usr, N)


	verb/unsuckable()
		usr.suckable = 0
		usr.bound = 0


