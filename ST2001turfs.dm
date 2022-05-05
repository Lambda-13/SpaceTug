var/list/doorDirs = list(0, 180, -90, 90, -45, 45, -135, 135)
var/cardinalDirs = list(1, 2, 4, 8)
var/allSophies[0]
var/currentAir


proc/BlowAirlock(mob/M)
	if(CheckGhostOrBrute(M)) return
	for(var/turf/door/D in world)
		if(D.z == M.z && D.AdjacentToSpace())
			D.Toggle()


proc/AbortSelfDestruct()
	if(locks["selfdestruct"] == 1 && !locks["destructwait"])
		SayPA("ИИ София", "Самоуничтожение отменено [usr].")
		locks["selfdestruct"] = 0
		locks["lastabort"] = world.time


proc/SelfDestruct()
	var/incept = world.time

	if(locks["selfdestruct"])
		usr << "Самоуничтожение уже запущено."
		return
	else
		locks["selfdestruct"] = 1

	for(var/mob/M in world)
		M.HearSound('reactor_2min_lhr.wav', 8, 44)
	SayPA("ИИ София", "Самоуничтожение запущено [usr].")
	sleep(600)

	if(locks["lastabort"] > incept) return
	for(var/mob/M in world)
		M.HearSound('reactor_1min_lhr.wav', 8, 22)
	sleep(300)

	if(locks["lastabort"] > incept) return
	for(var/mob/M in world)
		M.HearSound('reactor_30sec_lhr.wav', 8, 27)
	sleep(250)

	if(locks["lastabort"] > incept) return
	SayPA("ИИ София", "Пять.")
	sleep(10)

	if(locks["lastabort"] > incept) return
	SayPA("ИИ София", "Четыре.")
	sleep(10)

	if(locks["lastabort"] > incept) return
	SayPA("ИИ София", "Три.")
	sleep(10)

	if(locks["lastabort"] > incept) return
	SayPA("ИИ София", "Два.")
	sleep(10)

	if(locks["lastabort"] > incept) return
	SayPA("ИИ София", "Один.")
	sleep(10)

	if(locks["lastabort"] > incept) return
	locks["destructwait"] = 1
	for(var/area/A in world)
		if(A.type == /area/space) continue
		if(A.type == /area/room/shuttle2 && locks["shuttlelaunched"]) continue
		for(var/mob/M in A)
			M.Damage(999, "Стёрт с кораблём", 0)
		for(var/obj/O in A)
			del O
		for(var/turf/T in A)
			T.underlays.len = 0
			T.overlays.len = 0
			T.icon = null
			flick('explode.dmi', T)
		sleep(1)

	locks["destructwait"] = 0
	locks["selfdestruct"] = 2
	checkVictory = 1


obj
	atmosphere
		suckable = 0
		icon = 'atmosphere.dmi'


		New()
			. = ..()
			name = icon_state


obj/helper/hole
	icon = 'acid.dmi'
	icon_state = "hole"
	suckable = 0

	New()
		layer = OBJ_LAYER - 0.1
		spawn flick("burning", src)


turf
	var/splatterable = 1

	start_area
		icon = 'STlogo.dmi'

	proc/GetLaunchedStuff(turf/T)
		var/K
		for(K in T)
			if(ismob(K) || isobj(K))
				K:loc = src

	proc/StartAcid(myGeneration)
		new /obj/helper/hole(src)

		if(prob(100 - myGeneration * 45)) //0 = 100; 1 = 55; 2 = 10; 3+ = 0
			sleep(ACID_DELAY)
			SayPA("ИИ София", "Внимание. Нарушение герметичности в [loc].")

			if(AdjacentToVacuum()) PunchHole()
			else
				var/turf/T = locate(x, y, z - 1)
				if(T)
					if(istype(T, /turf/space))
						PunchHole()
					else spawn T.StartAcid(myGeneration + 1)


	proc/Get4AdjacentTurfs()
		var
			adjs[0]
			turf/T
			K

		for(K in cardinalDirs)
			T = get_step(src, K)
			if(T) adjs += T
		return adjs


	proc/Get6AdjacentTurfs()
		var
			adjs[0]

		adjs = Get4AdjacentTurfs()

		//fixme: check above & below turfs, to be safe.
		if(istype(src, /turf/floor/ladder))
			if(icon_state == "up" || icon_state == "updown")
				adjs += locate(x, y, z + 1)

			if(icon_state == "down" || icon_state == "updown")
				adjs += locate(x, y, z - 1)

		return adjs


	proc/AdjacentToSpace()
		var/turf/T
		for(T in Get4AdjacentTurfs())
			if(istype(T, /turf/space)) return T


	proc/AdjacentToVacuum()
		var/turf/T
		T = AdjacentToSpace()
		if(T) return T
		else
			for(T in Get4AdjacentTurfs())
				if(T.vacuumSource) return T


	Click()
		if(!density) walk_to(usr, src, 0, usr.moveDelay)


	space
		icon = 'space.dmi'
		splatterable = 0

		New()
			//Make it look all starry and stuff.
			if(prob(SPACE_DETAIL_PROB)) icon_state = num2text(rand(1, 4))


	sleeper
		icon = 'sleeper.dmi'
		icon_state = "sw"
		density = 1
		splatterable = 0

		GetLaunchedStuff(turf/sleeper/T)
			for(var/mob/M in T)
				usr = M
				T.awaken()

			..()

			for(var/mob/M in src)
				usr = M
				T.Sleep()

		verb/Sleep()
			set name = "лечь в слипер"
			set category = "Слипер"
			set src in range(usr, 1)

			if(CheckGhostOrBrute(usr)) return
			for(var/mob/M in src)
				if(!CheckGhost(M))
					usr << "Занято."
					return

			usr.loc = src
			usr.bound = 1
			usr.invisibility = 1
			usr.suckable = 0

			icon_state = "[icon_state]o" //swo or seo: occupied

			checkVictory = 1


		verb/awaken()
			set name = "выйти из слипера"
			set category = "Слипер"
			set src in range(usr, 1)

			if(CheckGhost(usr)) return

			for(var/mob/M in src)
				if(!CheckGhost(M) && (M != usr))
					M.loc = usr.loc
					M.bound = 0
					M.invisibility = 0
					M.suckable = 1

					switch(icon_state)
						if("swo") icon_state = "sw"
						if("seo") icon_state = "se"


	wall
		density = 1
		opacity = 1


		New()
			. = ..()
			if(name == "стена") name = loc:name


		dark_wall
			name = "стена"
			icon = 'dark_wall.dmi'

		hull
			icon = 'hull.dmi'
			icon_state = "Hrivets"

		white_wall
			name = "стена"
			icon = 'wall.dmi'

		beige_wall
			name = "стена"
			icon = 'wall2.dmi'

		pipe_wall
			name = "стена"
			icon = 'wall3.dmi'

		bridge_wall
			name = "стена"
			icon = 'wall4.dmi'

		sophie_wall
			name = "стена"
			icon = 'wall5.dmi'
			luminosity = 2


			New()
				. = ..()
				allSophies += src


		shaft_wall
			name = "стена"
			icon = 'wall6.dmi'

		chapel_wall
			name = "стена"
			icon = 'wall7.dmi'

		rust_wall
			name = "стена"
			icon = 'wall8.dmi'

		window
			name = "окно"
			icon = 'window.dmi'
			opacity = 0

		terminal
			name = "консоль"
			var/on = 0
			icon = 'terminal.dmi'
			icon_state = "off"
			splatterable = 0


			proc/TurnOn()
				if(on) return
				on = 1
				sleep(FLUO_INITIAL_DELAY)

				if(on && icon_state == "off")
					icon_state = "on"
					flick("powerup", src)


			proc/TurnOff()
				if(!on) return
				on = 0
				icon_state = "off"
				flick("shutdown", src)


			verb/blow_airlock()
				set name = "Уничтожить шлюз"
				set category = "консоль"
				set src = range(usr, 1)

				BlowAirlock(usr)


			verb/self_destruct()
				set name = "Активировать самоуничтожение"
				set category = "консоль"
				set src in range(usr, 1)

				if(CheckGhostOrBrute(usr)) return
				if(loc:type != /area/room/bridge)
					usr << "Доступ к этой функции возможен только с мостика."
					return

				var/sdOK = input(usr, "Ты уверен?", "Активировать самоуничтожение", "нет") \
					in list("нет", "да")
				if(sdOK == "да" && src in range(usr, 1)) spawn SelfDestruct()


			verb/abort_self_destruct()
				set name = "Отменить самоуничтожение"
				set category = "консоль"
				set src in range(usr, 1)

				if(CheckGhostOrBrute(usr)) return
				if(loc:type != /area/room/bridge)
					usr << "Доступ к этой функции возможен только с мостика."
					return

				var/sdOK = input(usr, "Ты уверен?", "Отменить самоуничтожение", "нет") \
					in list("нет", "да")
				if(sdOK == "да" && src in range(usr, 1)) spawn AbortSelfDestruct()


			verb/launch_shuttle()
				set name = "Запустить шаттл"
				set category = "консоль"
				set src in range(usr, 1)

				if(CheckGhostOrBrute(usr)) return
				if(loc:type != /area/room/shuttle)
					usr << "Доступ к этой функции возможен только с шаттла."
					return

				var/sdOK = input(usr, "Ты уверен?", "Запустить шаттл", "нет") \
					in list("нет", "да")
				if(sdOK == "да" && src in range(usr, 1))
					var/area/room/shuttle/S = locate()
					spawn S.Launch()


			verb/PA(T as text)
				set category = "консоль"
				set src = range(usr, 1)

				if(CheckGhostOrBrute(usr)) return
				SayPA(usr, T)


	floor
		icon = 'floor.dmi'
		splatterable = 1


		New()
			. = ..()
			if(name == "floor") name = loc:name
			if(loc:type == /area/space) spawn world << "Сломаный пол: [x] [y] [z]"
			currentAir++


		seat
			icon = 'seat.dmi'
			splatterable = 0


			verb/buckle()
				set src in range(usr, 1)

				if(CheckGhostOrBrute(usr)) return
				for(var/mob/M in src)
					if(!CheckGhost(M) && M != usr)
						usr << "Занято."
						return

				usr.loc = src
				usr.bound = 1
				usr.suckable = 0
				usr << "Пристёгнут."


			verb/unbuckle()
				set src in range(usr, 1)

				if(CheckGhost(usr)) return

				for(var/mob/M in src)
					if(!CheckGhost(M))
						M.loc = usr.loc
						M.bound = 0
						M.suckable = 1
						M << "Отстёгнут."


		table
			icon = 'obstacle.dmi'
			density = 1
			splatterable = 0

		generator
			icon = 'generator.bmp'
			density = 1

		containment
			icon = 'containment.bmp'
			density = 1

		ladder
			icon = 'ladder.dmi'
			splatterable = 0


			verb/climb()
				set name = "Подняться"
				set category = "Основное"
				set src = usr.loc
				usr << "Поднимаюсь."

				sleep(CLIMB_SLEEP)
				if(usr.loc == src)
					if(!usr.Move(locate(x, y, z + 1)))
						usr << "Не могу."


			verb/descend()
				set name = "Опуститься"
				set category = "Основное"
				set src = usr.loc

				usr << "Опускаюсь."
				sleep(DESCEND_SLEEP)
				if(src == usr.loc)
					if(!usr.Move(locate(x, y, z - 1)))
						usr << "Не могу."


			New()
				. = ..()
				if(icon_state == "down")
					verbs -= /turf/floor/ladder/verb/climb
				if(icon_state == "up")
					verbs -= /turf/floor/ladder/verb/descend


	door
		var
			open
			locked
		icon_state = "closed"
		density = 1
		opacity = 1
		splatterable = 0
		var/broken = 0


		proc/Break()
			OverlayManager.AddOverlay(src, 'flasher.dmi', "small")
			broken = 1


		verb/blow_airlock()
			set name = "уничтожить шлюз"
			set category = "шлюз"
			set src = range(usr, 1)

			BlowAirlock(usr)


		New()
			. = ..()
			if(loc:type == /area/space) spawn world << "Сломаный пол: [x] [y] [z]"

			spawn
				if(AdjacentToSpace()) Close()
				else
					var/obj/helper/doorCloser/D
					for(D in src)
						del D
						return
					//And if a door closer wasn't found, open the door
					Open()


		Click()
			if(CheckGhostOrBrute(usr)) return
			var/foundDoor = 0
			var/D
			for(D in range(usr, 1))
				if(istype(D, /turf/door))
					foundDoor = 1
					break

			if(foundDoor) Toggle()
			else . = ..()


		proc/Lock()
			locked = 1


		proc/Toggle()
			if(CheckGhostOrBrute(usr)) return

			if(!open) Open()
			else Close()


		verb/open()
			set name = "открыть"
			set category = "Основное"
			set src in range(1)
			if(CheckGhostOrBrute(usr)) return
			if(!open) Open()


		verb/close()
			set name = "закрыть"
			set category = "Основное"
			set src in range(1)
			if(CheckGhostOrBrute(usr)) return
			Close()


		proc/Open()
			set name = "открыть"
			set category = "Основное"
			if(!open && !locked)
				icon_state = "open"
				flick("opening", src)
				open = 1
				for(var/mob/M in range(src, VIEW))
					M.HearSound('door1.wav', 1, 12)
				spawn(DOOR_EFFECT_DELAY)
					if(open)
						density = 0
						opacity = 0
						SetVacuumSource(AdjacentToVacuum(), src)
						if(AdjacentToSpace())
							SayPA("ИИ София", "Внимание. Открытие наружного шлюза в [loc] спровоцировано [usr].")


		proc/Close()
			set name = "закрыть"
			set category = "Основное"
			if(open)
				if(broken)
					usr << "Сломано."
					return

				icon_state = "closed"
				flick("closing", src)
				open = 0
				for(var/mob/M in range(src, VIEW))
					M.HearSound('door1.wav', 1, 12)

				var/mob/M
				for(M in src)
					M.Damage(1, "Раздавлен шлюзом", 1)
					spawn Open()
					return

				spawn(DOOR_EFFECT_DELAY)
					if(!open)
						density = 1
						opacity = initial(opacity)
						SetVacuumSource(null)


		spiral_door
			name = "доступ к системе вентиляции"
			icon = 'spiralDoor.dmi'

		beige_door
			name = "шлюз"
			icon = 'door3.dmi'
			opacity = 0

		purina_door
			name = "шлюз"
			icon = 'door2.dmi'

		blue_door
			name = "шлюз"
			icon = 'door4.dmi'

obj
	var/suckable = 0

	intercom
		name = "интерком"
		icon = 'intercom.dmi'
		icon_state = "on"
		layer = TURF_LAYER + 0.1


		Click()
			if(CheckGhostOrBrute(usr)) return
			if(src in range(usr, 1))
				if(icon_state == "on") icon_state = "off"
				else icon_state = "on"


	fluorescent_light
		name = "лампа"
		icon = 'fluorescent.dmi'
		icon_state = "off"
		luminosity = 0
		var/on
		layer = TURF_LAYER + 0.1


		proc/TurnOn()
			if(on) return
			on = 1

			sleep(FLUO_INITIAL_DELAY)

			while(on && icon_state != "on")
				switch(icon_state)
					if("off")
						icon_state = pick(
							prob(100)
								"dim",
							prob(200)
								"off",
							prob(100)
								"on")
					if("dim")
						icon_state = pick(
							prob(200)
								"off",
							prob(100)
								"dim")

				switch(icon_state)
					if("off")
						luminosity = 0
					if("dim")
						luminosity = 2
					if("on")
						luminosity = 3
						return

				sleep(FLUO_FLICKER_DELAY)


		proc/TurnOff()
			on = 0
			icon_state = "off"
			luminosity = 0
