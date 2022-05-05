overlayManager
	var/icons[0]

	proc/RegisterIcon(myIcon, list/myStates, myLayer)
		//Create a reusable dummy overlay for each declared state of the icon.
		if(!icons[myIcon])
			icons[myIcon] = myStates
			var/obj/dummyO
			for(var/K in myStates)
				dummyO = new ()
				dummyO.icon = myIcon
				dummyO.icon_state = K
				if(myLayer) dummyO.layer = myLayer
				myStates[K] = dummyO

	proc/AddOverlay(turf/T, myIcon, myState)
		var/K = GetOverlay(myIcon, myState)
		T.overlays -= K
		T.overlays += K

	proc/RemoveOverlay(turf/T, myIcon, myState)
		var/K = GetOverlay(myIcon, myState)
		T.overlays -= K

	proc/AddRandomOverlay(turf/T, myIcon)
		var/K = GetRandomOverlay(myIcon)
		T.overlays -= K
		T.overlays += K

	proc/RemoveRandomOverlay(turf/T, myIcon)
		var/K = GetRandomOverlay(myIcon)
		T.overlays -= K

	proc/GetOverlay(myIcon, myState)
		var/list/L = icons[myIcon]
		return L[myState]

	proc/GetRandomOverlay(myIcon)
		var/list/L = icons[myIcon]
		var/myState = L[rand(1, L.len)]
		return L[myState]
