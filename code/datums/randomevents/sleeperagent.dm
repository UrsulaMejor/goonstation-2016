/datum/random_event/major/sleeper_agent
	name = "Awaken Sleeper Agents"
	required_elapsed_round_time = 16000 // 30m
	customization_available = 1
	announce_to_admins = 0 // Doing it manually.
	centcom_headline = "Enemy Signal Detected"
	centcom_message = "A Syndicate radio station temporarily hijacked our communications. Be wary of individuals acting strangely."
	message_delay = 50// 5s
	var/num_agents = 0
	var/lock = 0
	var/admin_override = 0
	var/signal_intro = 'sound/misc/sleeper_agent_hello.ogg'
	var/frequency = 1459
	var/sound_channel = 174
	var/list/numbers = list(0,0,0,0,0,0)
	var/list/listeners = list()
	var/list/candidates = list()

	admin_call(var/source)
		if (..())
			return

		if (src.lock != 0)
			message_admins("Setup of previous sleeper agents hasn't finished yet, aborting.")
			return

		var/agents = input(usr, "How many sleeper agents to awaken?", "Sleeper Agents", 0) as num
		if (!agents)
			return
		else
			src.num_agents = agents

		src.admin_override = 1
		src.event_effect(source)
		return

	event_effect(var/source)
		if(src.lock)
			return
		if (src.admin_override != 1)
			if (!source && (!ticker.mode || ticker.mode.latejoin_antag_compatible == 0 || late_traitors == 0))
				message_admins("Sleeper Agents are disabled in this game mode, aborting.")
				return
		spawn(0)
			src.lock = 1
			do_event()
			src.lock = 0

	proc/do_event()
		gen_numbers()
		gather_listeners()
		if (!listeners.len)
			return
		spawn (10)
			broadcast_sound(signal_intro)
			play_all_numbers()
			broadcast_sound(signal_intro)

		if(!src.admin_override)
			num_agents = rand(0,2)
		if(!num_agents)
			return

		sleep(300) //30s to let the signal play
		var/mob/living/carbon/human/H = null
		num_agents = min(num_agents,candidates.len)
		for(var/i = 0, i<num_agents,i++)
			H = pick(candidates)
			candidates -= H
			if(istype(H))
				awaken_sleeper_agent(H)

		if (src.centcom_headline && src.centcom_message && random_events.announce_events)
			spawn (src.message_delay)
				command_alert("[src.centcom_message]", "[src.centcom_headline]")

		src.admin_override = initial(src.admin_override)
		return

	proc/awaken_sleeper_agent(var/mob/living/carbon/human/H)
		var/list/eligible_objectives = list()
		eligible_objectives = typesof(/datum/objective/regular/) + typesof(/datum/objective/escape/) - /datum/objective/regular/
		var/num_objectives = rand(1,3)
		var/datum/objective/new_objective = null
		for(var/i = 0, i < num_objectives, i++)
			var/select_objective = pick(eligible_objectives)
			new_objective = new select_objective
			new_objective.owner = H.mind
			new_objective.set_up()
			H.mind.objectives += new_objective

		H.show_text("<h2><font color=red><B>You have awakened as a syndicate sleeper agent!</B></font></h2>", "red")
		H.mind.special_role = "hard-mode traitor"
		H << browse(grabResource("html/traitorTips/traitorhardTips.html"),"window=antagTips;titlebar=1;size=600x400;can_minimize=0;can_resize=0")
		if (H.mind.current)
			H.mind.current.antagonist_overlay_refresh(1, 0)
		var/obj_count = 1
		for(var/datum/objective/OBJ in H.mind.objectives)
			boutput(H, "<B>Objective #[obj_count]</B>: [OBJ.explanation_text]")
			obj_count++

	proc/gen_numbers()
		var/new_numbers = list()
		for(var/i in numbers)
			new_numbers += rand(1,99)
		numbers = new_numbers

	proc/gather_listeners()
		listeners = list()
		for (var/mob/living/carbon/human/H in world)
			for (var/obj/item/device/radio/Hs in H)
				if (Hs.frequency == frequency)
					listeners += H
					boutput(H, "<span style=\"color:blue\">A peculiar noise intrudes upon the radio frequency of your [Hs].</span>")
					if(H.client && !checktraitor(H))
						candidates += H
				break
		for (var/mob/living/silicon/robot/R in world)
			if (istype(R.radio, /obj/item/device/radio))
				var/obj/item/device/radio/Hs = R.radio
				if (Hs.frequency == frequency)
					listeners += R
					boutput(R, "<span style=\"color:blue\">A peculiar noise intrudes upon your radio frequency.</span>")

	proc/broadcast_sound(var/soundfile)
		for (var/mob/M in listeners)
			if (M.client)
				M << sound(soundfile, volume = 100, channel = sound_channel, wait = 1)


	proc/play_all_numbers()
		var/batch = 0
		var/period = get_vox_by_string(".")
		for (var/number in numbers)
			play_number(number)
			broadcast_sound(period)
			batch++
			if (batch >= 3)
				sleep(1)

	proc/get_tens(var/n)
		if (n >= 20)
			var/tens = round(n / 10)
			switch (tens)
				if (2)
					return "twenty"
				if (3)
					return "thirty"
				if (4)
					return "fourty"
				if (5)
					return "fifty"
				if (6)
					return "sixty"
				if (7)
					return "seventy"
				if (8)
					return "eighty"
				if (9)
					return "ninety"
		return null

	proc/get_ones(var/n)
		if (n == 0)
			return "zero"
		if (n >= 10 && n < 20)
			switch (n)
				if (10)
					return "ten"
				if (11)
					return "eleven"
				if (12)
					return "twelve"
				if (13)
					return "thirteen"
				if (14)
					return "fourteen"
				if (15)
					return "fifteen"
				if (16)
					return "sixteen"
				if (17)
					return "seventeen"
				if (18)
					return "eighteen"
				if (19)
					return "nineteen"
		else
			var/ones = n % 10
			switch (ones)
				if (1)
					return "one"
				if (2)
					return "two"
				if (3)
					return "three"
				if (4)
					return "four"
				if (5)
					return "five"
				if (6)
					return "six"
				if (7)
					return "seven"
				if (8)
					return "eight"
				if (9)
					return "nine"
		return null

	proc/get_vox_by_string(var/vt)
		if (!vt)
			return null
		var/datum/VOXsound/vs = voxsounds[vt]
		if (!vs)
			return null
		return vs.ogg

	proc/play_number(var/n)
		var/stens = get_tens(n)
		var/ogg = get_vox_by_string(stens)
		if (ogg)
			broadcast_sound(ogg)
		var/sones = get_ones(n)
		ogg = get_vox_by_string(sones)
		if (ogg)
			broadcast_sound(ogg)