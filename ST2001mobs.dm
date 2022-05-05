var/list/playerIcons = list('player.dmi', 'player2.dmi', 'player3.dmi', \
	'player4.dmi', 'player5.dmi', 'player6.dmi')
var/deathCauses[0]
var/list/turnDirs = list(-45, 45, -90, 90, -135, 135, 180)
var/checkVictory = 0


client
	New()
		. = ..()
		lazy_eye = LAZY_EYE

		if(prob(GROVEL_PROBABILITY)) spawn(10) Beg()

		//Add DM privileges
		if(ckey == "gughunter")
			mob.verbs += /dmverb/verb/showCPU
			mob.verbs += /dmverb/verb/unsuckable


	Del()
		world << "[mob] is catatonic with fear!"
		checkVictory = 1
		. = ..()


	Move(myLoc)
		//First attempt to move in a new direction just turns the mob.
		//Doesn't affect click-to-move.
		if(mob.doFacing)
			var/G = get_dir(mob, myLoc)
			if(G && G != mob.dir)
				mob.dir = G
				return

		if(mob.bound) return

		//Restrict the player's movement speed--will not affect NPC's,
		//nor external movement of the player's mob (via vacuum, conveyor belt, whatever)
		if(mob.lastMove + mob.moveDelay <= world.time)
			. = ..()
			if(.)
				mob.lastMove = world.time


	proc/Beg()
		var/confirmText = "Yes!"
		var/payNow = alert(mob, \
			"Would you like to donate one BYONDime toward bonus shares for the engineers?", \
			"Infrequent random prompt", confirmText, "Not now, thanks")
		if(payNow == confirmText)
//			if(mob.client.PayDimes(1,"Gughunter","SpaceTug donation"))
//				mob << "Thank you very much!"
			world << "Thanks, but you get a free pass for now!"


	Center()
		. = ..()

		//If player hits the 5 key, do whatever is most appropriate.

		//Scream if near a critter.
		var/mob/critter/C
		for(C in view(mob, 2))
			if((!istype(mob, /mob/critter)) && !CheckGhost(mob)) Say(mob, "Aieeeeeee!")
			break

		//Climb or descend if on a ladder.
		var/turf/floor/ladder/L = mob.loc
		if(istype(L))
			if(L.icon_state == "up" || L.icon_state == "updown") L:climb()
			else if(L.icon_state == "down") L:descend()
			return

		if(CheckGhost(mob)) return

		var/turf/T
		T = get_step(mob, mob.dir)
		if(T)
			//If facing a useful item, grab it.
			var/obj/portable/O
			for(O in T)
				O.get()
				return

			//If facing an intercom, toggle it.
			var/obj/intercom/I
			for(I in T)
				I.Click()
				return

		//If adjacent to a door, toggle it.
		//The doorDirs list is an attempt to determine which door is the most useful
		//when there is more than one adjacent door. It works well 95% of the time.
		for(var/K in doorDirs)
			T = get_step(mob, turn(mob.dir, K))
			if(T && istype(T, /turf/door))
				T:Click()
				return


mob
	var
		acidBlood = 0
		moveDelay = HUMAN_MOVE
		lastMove = -999999
		splatIcon
		health = 4
		bound = 0
		suckable = 1
		doFacing = 1
		maxPressure = DEFAULT_PRESSURE
		pressure = 0

		curSound
		curSoundPriority
		curSoundEnd


	verb/help()
		//Someday:	usr << file2text('SThelp.txt')
		usr << "Press the center (keypad 5) key to use doors, ladders, and so forth."


	verb/who()
		for(var/mob/M in world)
			if(M.client) usr << M


	proc/HearSound(mySound, myPriority, myDuration)
		if((!curSoundEnd) || world.time <= curSoundEnd)
			if(curSoundPriority >= myPriority) return

		src << sound(mySound)
		curSoundEnd = world.time + myDuration
		curSoundPriority = myPriority
		spawn(myDuration + 1) PlayBackground()

	proc/PlayBackground()
		if(curSoundEnd < world.time)
			curSoundPriority = 0
			if(isturf(loc))
				src << sound(loc:loc:backgroundSound, 1)

	Move()
		. = ..()
		if(.)
			for(var/obj/portable/motion_tracker/myMT in world)
				myMT.RegisterMove(src)


	New()
		. = ..()
		if(splatIcon)
			OverlayManager.RegisterIcon(splatIcon, list("1", "2", "3", "4"), \
				TURF_LAYER + 0.5) //same layer as soot


	Stat()
		if(statpanel("Carrying"))
			stat(contents)


	verb/say(T as text)
		Say(usr, T)


	verb/toggle_facing()
		if(doFacing) doFacing = 0
		else doFacing = 1
		usr << "Your ability to change facing without moving is now [GetOnOffText(doFacing)]."


	proc/Wander()
		var/turf/T = get_step(src, dir)
		if(!T || !Move(T) || prob(CHANGE_DIR_PROB))
			var/modifier = rand(0, 1) * 2 - 1
				//I.e., -1 or 1; this is so left or right turns will
				//get preference randomly.
			var/oldDir = dir
			for(var/K in turnDirs)
				//Try mild turns first, then sharper ones.
				dir = turn(oldDir, K * modifier)
				T = get_step(src, dir)
				if(T) if(Move(T)) break


	proc/Die(myDescription)
		deathCauses[src] = myDescription
		icon_state = "corpse"
		density = 0
		checkVictory = 1

//		if(client) --This line was causing the "bloody head" bug!
		var/mob/player/G = new(src.loc)
		G.icon = 'ghost.dmi'
		G.suckable = 0
		G.density = 0
		G.invisibility = 1
		G.sight |= SEEINVIS
		G.name = "[src]'s ghost"
		G.key = src.key


	proc/Damage(myAmount, myDescription, doSplat)
		if(health <= 0) return
		if(CheckGhost(src)) return

		if(doSplat) Splatter(myAmount)

		health -= myAmount
		src << "[myDescription]!"
			//Hence myDescription should be a short descriptive sentence, e.g.,
			//"Schnockered by Blatz", without punctuation.
		if(health <= 0)
			health = 0
			Die(myDescription) //Die() will save the description for end-of-game recap.


	proc/Splatter(myAmount)
		//Try to splatter myAmount turfs with blood, acid, whatever.
		//If fewer splatterable turfs are available,
		//all splatterable turfs will get one splat; otherwise choice is random.
		if(splatIcon)
			var/turf/T
			var/L[0]
			var/maxSplats = myAmount

			for(T in view(src, 1))
				if(T.splatterable) L += T

			if(L.len < maxSplats) maxSplats = L.len

			if(maxSplats)
				for(var/i = 1; i <= maxSplats; i++)
					T = L[rand(1, L.len)]
					if(acidBlood) spawn T.StartAcid(0)
					else OverlayManager.AddRandomOverlay(T, splatIcon)
					L -= T


	proc/Think()
		while(src && health > 0)
			if(!client)
				Wander()
			sleep(moveDelay)


	player
		splatIcon = 'humanSplat.dmi'
		icon = 'player.dmi'


		Login()
			//If loc is already set, the player probably disconnected and came back.
			if(CheckGhost(src)) return
			if(!loc)
				var/area/Dream_world/D = locate()
				for(var/turf/T in D)
					if(Move(T)) return
			else src << sound(MAIN_THEME, 1)


	critter
		var/sentient = 0
		splatIcon = 'critterSplat.dmi'


		New()
			. = ..()
			spawn Think()


		Allen //You can call him Al.
			icon = 'critter.dmi'
			name = "critter"
			var/minBump
			var/joltEndTime
			acidBlood = 1
			maxPressure = DEFAULT_PRESSURE * 1.5


			verb/attack(mob/M as mob in range(1))
				Attack(M)


			proc/Attack(mob/M)
				if(M.type == src.type) return

				flick("attack", src)

				for(var/mob/hearee in range(src, VIEW))
					hearee.HearSound('critter1.wav', 10, 9)

				M.Damage(1, "Critter attack", 1)


			Think()
				var/mob/player/target
				while(src && health > 0)
					if(!client)
						if(target)
							if(istype(target, /turf/floor/ladder) || target.health > 0)
								dir = get_dir(src, target)
							else target = null
						else
							if(world.time >= joltEndTime)
								target = locate() in view(src, 5)
								if(target && IsRoughlyFacing(src, target, 90))
									if((target.health <= 0) || CheckGhost(target)) target = null
									else target << sound('tense1.mid', 1)
							//The critter AI is really poor, and badly written too--but
							//luckily, most of the time a player is happy to step into
							//the critter's shoes.
							//fixme: look for ladder here
							//fixme: handle "flee"
							//fixme: handle music better--a simple flag would do

						Wander()

					else
						if(!target)
							target = locate() in view(src, 5)
							if(target)
								if((target.health <= 0) || CheckGhost(target)) target = null
								else target << sound('tense1.mid', 1)
						else
							if(target.health <= 0) target = null

					sleep(moveDelay)


			Bump(mob/M)
				if(istype(M))
					var/obj/portable/prod/P = locate() in M
					if(P && IsRoughlyFacing(M, src, 45) && prob(PROD_EFFECTIVENESS))
						dir = turn(dir, 180)
						joltEndTime = world.time + 30
						src << "You are temporarily stunned by the electric prod!"
						for(var/mob/hearee in range(src, VIEW))
							hearee.HearSound('zap.wav', 3, 2)
						return
					if(world.time >= joltEndTime)
						Attack(M)

				else
					if(istype(M, /turf/door))
						var/turf/door/T = M
						if(minBump <= world.time)
							minBump = world.time + \
								rand(ALIEN_BUMP_DOOR_WAIT / 2, ALIEN_BUMP_DOOR_WAIT)
							for(var/mob/hearee in range(src, VIEW))
								hearee.HearSound('hitdoor.wav', 4, 4)
							if(prob(ALIEN_OPEN_DOOR_PROB))
								T.Open()

								SayPA("Aunt Sophie", "Warning. Door malfunction in [T.loc].")

								if(prob(ALIEN_BREAK_DOOR_PROB))
									T.Break()


	cat
		splatIcon = 'humanSplat.dmi'
		density = 0
		icon = 'cat.dmi'
		health = 2
		maxPressure = 50


		Move()
			//Allow cat to be blocked by walls, etc. without getting in players' way.
			density = 1
			. = ..()
			density = 0


		Click()
			//Allow players to rescue cat
			if(CheckGhost(usr)) return
			if(usr in range(src, 1)) src.Move(usr)


		New()
			. = ..()
			spawn Think()


		Think()
			//Don't move if picked up by player!
			while(src && health > 0)
				if(ismob(loc)) return
				//This code is copied from parent class Think(), because calling ..()
				//will sleep within *that* proc and never check for location in player contents!
				Wander()
				sleep(moveDelay)


		Die()
			Say(src, "Ack!")
			. = ..()
