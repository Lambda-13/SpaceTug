var
	vSpreading[0]
	vClearing[0]
	vSucked[0]

turf/proc/PunchHole()
	if(istype(src, /turf/space)) return
	SetVacuumSource(src)

turf/var
	turf/vacuumSource
	turf/vacuumRoot

proc/MaintainVacuum()
	var/list
		tempSpreading
		tempClearing
	var/turf/T
	var/flux = 0
	var/originalAir = currentAir
	var/airVolume = currentAir
	var/lastStable = currentAir

	spawn MaintainSuck()
	spawn MaintainPressure()

	while(1)

		if(vSpreading.len)
			flux = 1
			tempSpreading = vSpreading
			vSpreading = list()
			for(T in tempSpreading)
				T.SpreadVacuum()

		if(vClearing.len)
			flux = 1
			tempClearing = vClearing
			vClearing = list()
			for(T in tempClearing)
				T.ClearVacuum()

		if(!flux)
			if(currentAir < lastStable)
				var/airReduction = airVolume - (airVolume * (currentAir / lastStable))
				if(airReduction >= originalAir * 0.01)
					airVolume -= airReduction
					if(airVolume < 0) airVolume = 0
					SayPA("Aunt Sophie", "Warning. Air reserves now at \
					[100 * airVolume / originalAir] percent.")

			lastStable = currentAir
		else
			if(DEBUG_AIR)
				world << "[vSpreading.len] [vClearing.len] [originalAir] [airVolume] [currentAir] [lastStable]"

		flux = 0

		sleep(VACUUM_SLEEP)


proc/MaintainPressure()
	var/mob/M
	var/oldPress
	while(1)
		for(M in world)
			if(CheckGhost(M)) continue
			if(isturf(M.loc) && (M.loc:vacuumSource || istype(M.loc, /turf/space)))
				oldPress = M.pressure
				if(!oldPress) oldPress = 1 //avoid div by 0
				M.pressure += PRESSURE_SLEEP
				if(M.pressure && (round(M.maxPressure / M.pressure) == round(M.maxPressure / oldPress)))
					M << "Pressure building!"

				if(M.pressure > M.maxPressure)
					M.pressure = -999999
					flick("explode", M)
					sleep (12)
					if(M) M.Damage(999, "Depressurized", 1)
			else if(M.pressure > 0) M.pressure -= 1

		sleep(PRESSURE_SLEEP)


proc/MaintainSuck()
	while(1)
		var/K
		for(K in vSucked)
			if(!K || !K:suckable)
				vSucked -= K
				continue

			if(istype(K:loc, /turf/space))
				if(ismob(K)) K:bound = 1
				step(K, K:dir)
				continue

			if(isturf(K:loc))
				if(K:loc:vacuumSource)
					K:Move(K:loc:vacuumSource)
				else
					vSucked -= K

		sleep(SUCK_SLEEP)

turf/proc
	SetVacuumSource(turf/mySource, turf/myRoot)
		if(!vacuumSource)
			if(mySource)
				vacuumSource = mySource
				if(istype(src, /turf/floor)) currentAir--
				// && src.loc:type != /area/room/shuttle2 -- for extra accuracy, if needed.

				if(myRoot) vacuumRoot = myRoot
				else if(mySource.vacuumRoot) vacuumRoot = mySource.vacuumRoot
				else vacuumRoot = src

				Suck()
				vSpreading += src
				vClearing -= src

		else
			if(!mySource)
				vacuumSource = null
				vacuumRoot = null
				if(istype(src, /turf/floor)) currentAir++
				vClearing += src
				vSpreading -= src


	SpreadVacuum()
		if(!(vacuumRoot:vacuumSource)) return
		var/turf/T
		for(T in Get6AdjacentTurfs())
			if((!istype(T, /turf/space)) && (!T.vacuumSource) && (!T.density))
				T.SetVacuumSource(src)

	ClearVacuum()
		var/turf/T
		for(T in Get6AdjacentTurfs())
			if(T.vacuumSource == src)
				T.SetVacuumSource(null)
			else
				if(T.vacuumSource && T.vacuumRoot:vacuumSource) vSpreading += T

	Suck()
		if(!vacuumSource) return
		var/K
		for(K in contents)
			if(!isturf(K))
				if(K:suckable && !vSucked.Find(K))
					vSucked += K

turf
	Entered()
		Suck()
