proc/GetID()
	var/static/ID = 0
	return ID++


proc/ShowCPU(mob/M, myDelay)
	if(!myDelay) myDelay = SHOW_CPU_SLEEP
	while(CPUOn)
		M << "CPU [world.cpu]"
		sleep(myDelay)


proc/AssignPlayerIcon(mob/M)
	var/I = playerIcons[rand(1, playerIcons.len)]
	M.icon = I
	if(playerIcons.len > 1) playerIcons -= I


proc/MaintainSophies()
	//Makes the computer lights flash cheesily.
	while(1)
		for(var/turf/wall/sophie_wall/S in allSophies)
			if(prob(50)) OverlayManager.AddRandomOverlay(S, 'wall5.dmi')
			else OverlayManager.RemoveRandomOverlay(S, 'wall5.dmi')
		sleep(SOPHIE_SLEEP)


proc/GetOnOffText(x)
	if(x) return "ON"
	else return "OFF"


proc/IsNearComms(mob/M)
	//fixme: doesn't handle radios in mob contents!
	if(locate(/obj/portable/walkie_talkie, range(M, WALKIE_TALKIE_RANGE))) return "on radio:"
	for(var/obj/intercom/I in range(M, INTERCOM_RANGE))
		if(I.icon_state == "on") return "on intercom:"


proc/AlterPropriety(obj/target, myFlag)
	if(myFlag) target.name = "\proper [target.name]"
	else target.name = "\improper [target.name]"


proc/SayPA(speaker, Z)
	if(locks["selfdestruct"] == 2) return
	var/T = "<b>[speaker] on PA system: [Z]</b>"
	for(var/mob/M in world)
		M << T
	world.log << T


proc/Say(speaker, T)
	var/mob/M
	var/K
	var/sayTargets[0] //A list of everyone who will hear the message.

	//Everyone within a range of world.view will hear it.
	for(M in range(speaker, VIEW))
		sayTargets[M] = "says:"

	//Record the horror for posterity.
	sayTargets += world.log

	//If the person speaking is near a comm device (intercom or walkie-talkie),
	//transmit the message to other people near comm devices.
	var/device
	for(M in world)
		if(!sayTargets.Find(M))
			if(CheckGhost(M)) sayTargets[M] = "says:" //ghosts hear everything
			else if(IsNearComms(speaker))
				device = IsNearComms(M)
				if(device) sayTargets[M] = device

	var/hearers = 0
	for(K in sayTargets)
		K << "<b>[speaker] [sayTargets[K]]</b> [T]"
		if(ismob(K) && K:client) ++hearers
	speaker << "<small>Heard by [hearers] player\s.</small>"


proc/CheckGhost(mob/M)
	if(!M) return
	if(M.icon == 'ghost.dmi') return 1


proc/CheckNotSentient(mob/critter/M)
	//This is to support critter types that can do things like opening doors.
	if(!M) return
	if(istype(M))
		if(!M:sentient) return 1


proc/CheckGhostOrBrute(mob/M)
	return(CheckGhost(M) || CheckNotSentient(M))


proc/PutInPlace(mob/M, myType, unusable)
	//Put M in an area of myType.
	//L could be a single type, or a list of types, because subtracting one list from
	//another actually subtracts all *elements* of the subtracted list.
	var/list/L = typesof(myType)
	if(unusable) L -= unusable

	var/R
	while(1)
		R = locate(L[rand(1, L.len)])
		if(R)
			var/turf/floor/F
			for(F in R)
				if(M.Move(F)) return 1

		sleep(1)
		//fixme: This could potentially fail, I think.


proc/IsRoughlyFacing(mob/M, mob/M2, myAngle)
	//Returns 1 if M is facing M2 or only myAngle degrees off.
	//myAngle should be a multiple of 45.
	var/G = get_dir(M, M2)
	var/curAngle
	for(curAngle = -myAngle; curAngle <= myAngle; curAngle += 45)
		if(M.dir == turn(G, curAngle)) return 1
