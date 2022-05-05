area
	var/realm = "none"
		//This var is used to aid in the end-of-game victory detection.

	var/backgroundSound = 'bkgrndGeneral.wav'

	New()
		. = ..()
		//If the area contains fluorescent lights, it's always dark unless someone is in there.
		spawn
			for(var/obj/fluorescent_light/F in src)
				luminosity = 0
				break



	Entered(mob/M)
		if(istype(M) && !CheckGhost(M))
			for(var/obj/fluorescent_light/F in src)
				spawn F.TurnOn()
			for(var/turf/wall/terminal/T in src)
				spawn T.TurnOn()


	Exited(mob/M)
		//If mob leaves area and there are no other mobs remaining in area, turn off
		//fluorescents.
		if(istype(M) && !CheckGhost(M))
			var/found_other = 0
			for(var/mob/MM in src)
				if(M != MM) //fixme: check that MM isn't a ghost
					found_other = 1
					break

			if(!found_other)
				for(var/obj/fluorescent_light/F in src)
					F.TurnOff()
				for(var/turf/wall/terminal/T in src)
					T.TurnOff()


	Dream_world
		Enter(mob/M)
			//An object can't drift in from space, but can enter at game start.
			if(istype(M.loc, /turf/space) || M.icon == 'ghost.dmi') return 0
			else return 1


		Entered(mob/player/M)
			. = ..()
			if(istype(M))
				M << "Welcome to SpaceTug, by Gughunter. Suspense theme by Gazoot. Main theme by Beethoven.<p>"
				M << \
"<b>You are a crew member of the commercial towing vehicle <i>Monstoro.</i><p>\
When you type 'start' or leave this area, you will join a crisis already in progress.\
<p>There is a critter \
aboard the ship, and it will kill you and your crewmates one by one unless you can stop it.<p>"
				M << "<p>Type <b>help</b> for instructions."


		Exited(mob/player/M)
			//Alternative to typing 'start': just walk out of the area.
			. = ..()
			usr = M; start()

		verb/start()
			var/mob/critter/C
			var/playableCritters

			usr.loc = null
			sleep(10)

			for(C in world)
				if(!C.client)
					playableCritters = 1 && PLAY_AS_CRITTER
					break

			if(playableCritters)
				var/playCritter = input(usr, "Do you want to play as a critter?", null, "no") \
					in list("yes", "no")
				if(playCritter == "yes")
					for(C in world)
						if(!C.client)
							C.key = usr.key
							return

					usr << "Sorry--all playable critters are taken now. \
						You will be a regular player."

			if(PutInPlace(usr, PLAYER_START_AREA))
				AssignPlayerIcon(usr)

				for(var/mob/M in world)
					M.HearSound('newplayer.wav', 9, 41)

				(world.contents - usr) << "[usr] is ready to help."

				usr << "The horror has begun.\nHave fun!"
					//A tribute to the original Resident Evil (great atmosphere, inane puzzles):
					//"You have once again entered the world of survival horror. Good luck!"
					//Be sure to say "Good luck!" in a really cheerful tone of voice.

				spawn(41) usr << sound(MAIN_THEME, 1)
					//Background music: Moonlight Sonata (Beethoven)


	space

	room
		realm = "ship"

		airlock
			New()
				. = ..(); AlterPropriety(src, 1)
					//AlterPropriety prevents the computer from making embarrassing
					//blunders like "...in the airlock 2a."

			airlock_2a
			airlock_3a
			airlock_4a

		Aunt_Sophie
		bridge
		chapel
		garage
		generator_room
		infirmary

		Mess
			New()
				. = ..(); AlterPropriety(src, 0)

		maintenance_access
			New()
				. = ..(); AlterPropriety(src, 1)

			maintenance_access_2a
			maintenance_access_2b
			maintenance_access_2c

			maintenance_access_3a
			maintenance_access_3b
			maintenance_access_3c

			maintenance_access_4a
			maintenance_access_4b
			maintenance_access_4c

		observation_pod
		power_plant
		ramp

		shuttle
			proc/Launch()
				if(locks["shuttlelaunched"])
					usr << "Already launched."
					return
				else locks["shuttlelaunched"] = 1

				for(var/turf/door/D in contents)
					if(D.open)
						D.Close()
						D.Lock()
						//fixme: In theory, one or both of these calls could fail, I think.

				spawn(DOOR_EFFECT_DELAY + 1)
					SayPA("Aunt Sophie", "Shuttle has been launched by [usr].")

				var/turf/SB = locate("shuttleBase")
				var/turf/FSB = locate("fakeShuttleBase")

				var/turf/companion
				for(var/turf/T in src)
					companion = locate(T.x + FSB.x - SB.x, T.y + FSB.y - SB.y, T.z + FSB.z - SB.z)
					companion.GetLaunchedStuff(T)

		shuttle2
			name = "shuttle"
			realm = "shuttle"

		sleep_chamber

		storage
			New()
				. = ..(); AlterPropriety(src, 1)

			storage_2a
			storage_2b
			storage_2c

			storage_3a
			storage_3b
			storage_3c

			storage_4a
			storage_4b
			storage_4c

		theater
		turbine_room

		unnamed
			unnamed_2a
			unnamed_2b
			unnamed_2c
			unnamed_2d

			unnamed_3a
			unnamed_3b
			unnamed_3c
			unnamed_3d

			unnamed_4a
			unnamed_4b
			unnamed_4c
			unnamed_4d

	corridor
		realm = "ship"

		New()
			. = ..(); AlterPropriety(src, 1)

		corridor_1a
		corridor_2a
		corridor_2b
		corridor_2c
		corridor_2d
		corridor_2e
		corridor_2f
		corridor_2g
		corridor_2h

		corridor_3a
		corridor_3b
		corridor_3c
		corridor_3d
		corridor_3e
		corridor_3f
		corridor_3g
		corridor_3h

		corridor_4a
		corridor_4b
		corridor_4c
		corridor_4d
		corridor_4e
		corridor_4f
		corridor_4g
		corridor_4h

	junction
		realm = "ship"

		New()
			. = ..(); AlterPropriety(src, 1)

		junction_2a
		junction_2b
		junction_2c
		junction_2d

		junction_3a
		junction_3b
		junction_3c
		junction_3d

		junction_4a
		junction_4b
		junction_4c
		junction_4d

	ventilation_shaft
		realm = "ship"

		luminosity = 0


		New()
			. = ..(); AlterPropriety(src, 1)



		Entered(mob/player/M)
			. = ..()
			if(istype(M) && !CheckGhost(M)) M.moveDelay = initial(M.moveDelay) + VENTSHAFT_SLOWDOWN_TICKS


		Exited(mob/player/M)
			. = ..()
			//Note: if, in the future, other things can affect the player's movement speed
			//(e.g., wounded legs), this code and the code in Entered() will be inadequate.
			//Leaving the ventilation shaft would heal the player's legs!
			if(istype(M)) M.moveDelay = initial(M.moveDelay)


		climate_control
		ventilation_shaft_2a
		ventilation_shaft_2b
		ventilation_shaft_2c
		ventilation_shaft_2d

		ventilation_shaft_3a
		ventilation_shaft_3b
		ventilation_shaft_3c
		ventilation_shaft_3d

		ventilation_shaft_4a
		ventilation_shaft_4b
		ventilation_shaft_4c
		ventilation_shaft_4d
