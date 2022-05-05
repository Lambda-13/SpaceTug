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
	name = "SpaceTug"
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
				world << "\n<b>The humans win!</b>"
				spawn Recap()
			if(/mob/critter)
				world << \
					"\n<b>The Monstoro returns to Earth with [critterCount] critter\s on board. \
					All hell breaks loose!</b>"
				spawn Recap()
			else
				switch(shuttleType)
					if(/mob/player)
						world << \
							"\n<b>The ship is lost, but some of the crew survived. The \
							Interstate Commerce Commission will have plenty of questions!</b>"
						spawn Recap()
					if(/mob/critter)
						world << \
							"\n<b>The shuttle is packed with crittery goodness.</b>"
						spawn Recap()
					else
						world << \
							"\n<b>No critters remain! That's a victory for Earth... \
							but not much consolation to the crew.</b>"
						spawn Recap()


	proc/Recap()
		locks["victory"] = 1
		if(deathCauses.len)
			world << "<p><b><u>They Were Expendable</u></b><br>"
			for(var/K in deathCauses)
				world << "[K]: [deathCauses[K]]"
		world << "<p>Reboot in [REBOOT_DELAY / 10] seconds."
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


