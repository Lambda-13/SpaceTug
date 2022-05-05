obj/portable
	motion_tracker
		icon = 'Motion_tracker.dmi'
		var/mob/owner

		New()
			spawn Maintain()

		proc
			Maintain()
				while(src)
					if(owner)
						if(!(loc == owner)) owner = null
					else
						if(ismob(loc)) owner = loc
					sleep(11) //not much point in making this configurable... yet

			RegisterMove(mob/M)
				var/tempDir
				if(!owner || M.z < owner.z - 1 || M.z > owner.z + 1) return

				if(!(owner.dir in cardinalDirs)) tempDir = turn(owner.dir, 45)
				else tempDir = owner.dir

				var
					minX; minY; maxX; maxY
					llcX; llcY

				switch(tempDir)
					if(1)
						minX = owner.x - 9
						maxX = owner.x + 8
						minY = owner.y
						maxY = owner.y + 17
						llcX = -1
						llcY = 1
					if(2)
						minX = owner.x - 9
						maxX = owner.x + 8
						minY = owner.y - 17
						maxY = owner.y
						llcX = -1
						llcY = -3
					if(4)
						minX = owner.x
						maxX = owner.x + 17
						minY = owner.y - 9
						maxY = owner.y + 8
						llcX = 1
						llcY = -1
					if(8)
						minX = owner.x - 17
						maxX = owner.x
						minY = owner.y - 9
						maxY = owner.y + 8
						llcX = -3
						llcY = -1

				if(M.x < minX || M.x > maxX || M.y < minY || M.y > maxY) return

				var/xTile = round((M.x - minX) / 6)
				var/yTile = round((M.y - minY) / 6)

				var/xSlot = round(((M.x - minX) % 6) / 2) * 2 + 1
				var/ySlot = round(((M.y - minY) % 6) / 2) * 2 + 1

				var/myState = num2text(xSlot) + num2text(ySlot)

				ShowBlip(owner.x + llcX + xTile, owner.y + llcY + yTile, owner.z, myState)

			ShowBlip(myX, myY, myZ, myState)
				var/obj/dummyO = OverlayManager.GetOverlay('blip.dmi', myState)

				if(!dummyO) world << "Error: state [myState] not registered."

				var/turf/myTurf = locate(myX, myY, myZ)
				if(myTurf)
					var/curImage = image(dummyO, myTurf)
					owner << curImage

					spawn(13) del curImage
