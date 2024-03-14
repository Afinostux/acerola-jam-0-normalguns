package sprite

import rl "vendor:raylib"

NormalgunsSrc:: struct {
    // climb parts
    wingClimb:          Part,
    helmetClimb:        Part,
    bodyClimb:          Part,
    footRClimb:         Part,
    footRClimbGrip:     Part,
    footLClimb:         Part,
    footLClimbGrip:     Part,
    handRClimbClaw:     Part,
    handRClimb:         Part,
    handRClimbGripClaw: Part,
    handRClimbGrip:     Part,
    handLClimbClaw:     Part,
    handLClimb:         Part,
    handLClimbGripClaw: Part,
    handLClimbGrip:     Part,
    hairHighClimb:      Part,
    hairLowClimb:       Part,
    hornClimb:          Part,

    // head parts
    headPivot:          [2]f32,
    head:               Part,
    helmet:             Part,
    glasses:            Part,
    mask:               Part,
    hairLow:            Part,
    hairHigh:           Part,
    mouth:              Part,
    mouthHunger:        Part,
    eyes:               Part,
    eyesBlink:          Part,
    eyesLaser:          Part,
    horns:              Part,
    flameGill:          Part,

    // body parts
    bodyPivot:          [2]f32,
    body:               Part,
    wing:               Part,
    wingDown:           Part,
    spikes:             Part,

    // weapon parts
    knife:              Part,
    knifeClaw:          Part,
    rifle:              Part,
    rifleClaw:          Part,
    shotgun:            Part,
    shotgunClaw:        Part,
    grenade:            Part,
    grenadeClaw:        Part,
    rocket:             Part,
    rocketClaw:         Part,

    // foot parts
    footLeft:           Part,
    footRight:          Part,
}
normalgunsSrc: NormalgunsSrc

@(private)
init_normalguns:: proc()
{
    jsn: = get_json("normalguns.json")
    headFrame: = jsn.frames["Head"]
    headPivot: = aseprite_rect_mid_pivot(headFrame.spriteSourceSize)
    headInfo: = []PsCreateInfo{
        { headFrame, jsn.meta, 1 },
    }
    helmetInfo: = []PsCreateInfo{
        { jsn.frames["Helmet"], jsn.meta, 1 },
    }
    glassesInfo: = []PsCreateInfo{
        { jsn.frames["Glasses"], jsn.meta, 1 },
    }
    maskInfo: = []PsCreateInfo{
        { jsn.frames["Mask"], jsn.meta, 1 },
    }
    hairLowInfo: = []PsCreateInfo{
        { jsn.frames["Hair_low"], jsn.meta, 1 },
    }
    hairHighInfo: = []PsCreateInfo{
        { jsn.frames["Hair_high"], jsn.meta, 1 },
    }
    mouthInfo: = []PsCreateInfo{
        { jsn.frames["Mouth"], jsn.meta, 1 },
    }
    mouthHungerInfo: = []PsCreateInfo{
        { jsn.frames["Mouth_Hunger"], jsn.meta, 1},
    }
    eyesInfo: = []PsCreateInfo{
        { jsn.frames["Eyes"], jsn.meta, 1 },
    }
    eyesBlinkInfo: = []PsCreateInfo{
        { jsn.frames["Eyes_blink"], jsn.meta, 1 },
    }
    eyesLaserInfo: = []PsCreateInfo{
        { jsn.frames["Eyes_Laser"], jsn.meta, 1 },
    }
    hornsInfo: = []PsCreateInfo{
        { jsn.frames["Horn_R"], jsn.meta, 1 },
        { jsn.frames["Horn_L"], jsn.meta, 0 },
    }
    flameGillInfo: = []PsCreateInfo{
        { jsn.frames["Flame_Gill"], jsn.meta, 1 },
    }

    wingClimbInfo: = []PsCreateInfo{
        { jsn.frames["Wing_Climb"], jsn.meta, 4 },
    }
    helmetClimbInfo: = []PsCreateInfo{
        { jsn.frames["Helmet_Climb"], jsn.meta, 3 },
    }
    bodyClimbInfo: = []PsCreateInfo{
        { jsn.frames["Body_Climb"], jsn.meta, 2 },
    }
    footRClimbInfo: = []PsCreateInfo{
        { jsn.frames["Foot_R_Climb"], jsn.meta, 0 },
    }
    footRClimbGripInfo: = []PsCreateInfo{
        { jsn.frames["Foot_R_Climb_Grip"], jsn.meta, 0 },
    }
    footLClimbInfo: = []PsCreateInfo{
        { jsn.frames["Foot_L_Climb"], jsn.meta, 0 },
    }
    footLClimbGripInfo: = []PsCreateInfo{
        { jsn.frames["Foot_L_Climb_Grip"], jsn.meta, 0 },
    }
    handRClimbClawInfo: = []PsCreateInfo{
        { jsn.frames["Hand_R_Climb_Claw"], jsn.meta, 0 },
    }
    handRClimbInfo: = []PsCreateInfo{
        { jsn.frames["Hand_R_Climb"], jsn.meta, 0 },
    }
    handRClimbGripClawInfo: = []PsCreateInfo{
        { jsn.frames["Hand_R_Climb_Grip_Claw"], jsn.meta, 0 },
    }
    handRClimbGripInfo: = []PsCreateInfo{
        { jsn.frames["Hand_R_Climb_Grip"], jsn.meta, 0 },
    }
    handLClimbClawInfo: = []PsCreateInfo{
        { jsn.frames["Hand_L_Climb_Claw"], jsn.meta, 0 },
    }
    handLClimbInfo: = []PsCreateInfo{
        { jsn.frames["Hand_L_Climb"], jsn.meta, 0 },
    }
    handLClimbGripClawInfo: = []PsCreateInfo{
        { jsn.frames["Hand_L_Climb_Grip_Claw"], jsn.meta, 0 },
    }
    handLClimbGripInfo: = []PsCreateInfo{
        { jsn.frames["Hand_L_Climb_Grip"], jsn.meta, 0 },
    }
    hairHighClimbInfo: = []PsCreateInfo{
        { jsn.frames["Hair_high_Climb"], jsn.meta, 3 },
    }
    hairLowClimbInfo: = []PsCreateInfo{
        { jsn.frames["Hair_low_Climb"], jsn.meta, 3 },
    }
    hornClimbInfo: = []PsCreateInfo{
        { jsn.frames["Horn_Climb"], jsn.meta, 3 },
    }

    bodyPivot: = [2]f32{ 48, 56 }
    bodyInfo: = []PsCreateInfo{
        { jsn.frames["Body"], jsn.meta, 0 },
    }
    wingInfo: = []PsCreateInfo{
        { jsn.frames["Wing"], jsn.meta, 0 },
    }
    wingDownInfo: = []PsCreateInfo{
        { jsn.frames["Wing_Down"], jsn.meta, 0 },
    }
    spikesInfo: = []PsCreateInfo{
        { jsn.frames["Spikes"], jsn.meta, 0 },
    }

    knifeInfo: = []PsCreateInfo{
        { jsn.frames["Hand_L_Knife"], jsn.meta, -1 },
        { jsn.frames["Hand_R_Knife"], jsn.meta, 2 },
    }
    rifleInfo: = []PsCreateInfo{
        { jsn.frames["Rifle"],        jsn.meta, 2 },
        { jsn.frames["Hand_L_Rifle"], jsn.meta, 2 },
        { jsn.frames["Hand_R_Rifle"], jsn.meta, 2 },
    }
    shotgunInfo: = []PsCreateInfo{
        { jsn.frames["Shotgun"],        jsn.meta, 2 },
        { jsn.frames["Hand_L_Shotgun"], jsn.meta, 2 },
        { jsn.frames["Hand_R_Shotgun"], jsn.meta, 2 },
    }
    grenadeInfo: = []PsCreateInfo{
        { jsn.frames["Grenade"],        jsn.meta, 2 },
        { jsn.frames["Hand_L_Grenade"], jsn.meta, 2 },
        { jsn.frames["Hand_R_Grenade"], jsn.meta, 2 },
    }
    rocketInfo: = []PsCreateInfo{
        { jsn.frames["Rocket"],        jsn.meta, 2 },
        { jsn.frames["Hand_L_Rocket"], jsn.meta, 2 },
        { jsn.frames["Hand_R_Rocket"], jsn.meta, 2 },
    }
    knifeClawInfo: = []PsCreateInfo{
        { jsn.frames["Hand_L_Claw"], jsn.meta, -1 },
        { jsn.frames["Hand_R_Claw"], jsn.meta, 2 },
    }
    rifleClawInfo: = []PsCreateInfo{
        { jsn.frames["Rifle"],             jsn.meta, 2 },
        { jsn.frames["Hand_L_Claw_Rifle"], jsn.meta, 2 },
        { jsn.frames["Hand_R_Claw_Rifle"], jsn.meta, 2 },
    }
    shotgunClawInfo: = []PsCreateInfo{
        { jsn.frames["Shotgun"],             jsn.meta, 2 },
        { jsn.frames["Hand_L_Claw_Shotgun"], jsn.meta, 2 },
        { jsn.frames["Hand_R_Claw_Shotgun"], jsn.meta, 2 },
    }
    grenadeClawInfo: = []PsCreateInfo{
        { jsn.frames["Grenade"],             jsn.meta, 2 },
        { jsn.frames["Hand_L_Claw_Grenade"], jsn.meta, 2 },
        { jsn.frames["Hand_R_Claw_Grenade"], jsn.meta, 2 },
    }
    rocketClawInfo: = []PsCreateInfo{
        { jsn.frames["Rocket"],             jsn.meta, 2 },
        { jsn.frames["Hand_L_Claw_Rocket"], jsn.meta, 2 },
        { jsn.frames["Hand_R_Claw_Rocket"], jsn.meta, 2 },
    }

    footLeftFrame: = jsn.frames["Boot_L"]
    footLeftPivot: = aseprite_rect_mid_pivot(footLeftFrame.spriteSourceSize)
    footLeftInfo: = []PsCreateInfo{
        { footLeftFrame, jsn.meta, -1 },
    }

    footRightFrame: = jsn.frames["Boot_R"]
    footRightPivot: = aseprite_rect_mid_pivot(footLeftFrame.spriteSourceSize)
    footRightInfo: = []PsCreateInfo{
        { footRightFrame, jsn.meta, 1 },
    }

    HALF_SIZE:: 48
    normalgunsSrc = NormalgunsSrc{
        // climb parts
        wingClimb          = create_part(wingClimbInfo,          bodyPivot,      HALF_SIZE),
        helmetClimb        = create_part(helmetClimbInfo,        headPivot,      HALF_SIZE),
        bodyClimb          = create_part(bodyClimbInfo,          bodyPivot,      HALF_SIZE),
        footRClimb         = create_part(footRClimbInfo,         {},             HALF_SIZE),
        footRClimbGrip     = create_part(footRClimbGripInfo,     {},             HALF_SIZE),
        footLClimb         = create_part(footLClimbInfo,         {},             HALF_SIZE),
        footLClimbGrip     = create_part(footLClimbGripInfo,     {},             HALF_SIZE),
        handRClimbClaw     = create_part(handRClimbClawInfo,     {},             HALF_SIZE),
        handRClimb         = create_part(handRClimbInfo,         {},             HALF_SIZE),
        handRClimbGripClaw = create_part(handRClimbGripClawInfo, {},             HALF_SIZE),
        handRClimbGrip     = create_part(handRClimbGripInfo,     {},             HALF_SIZE),
        handLClimbClaw     = create_part(handLClimbClawInfo,     {},             HALF_SIZE),
        handLClimb         = create_part(handLClimbInfo,         {},             HALF_SIZE),
        handLClimbGripClaw = create_part(handLClimbGripClawInfo, {},             HALF_SIZE),
        handLClimbGrip     = create_part(handLClimbGripInfo,     {},             HALF_SIZE),
        hairHighClimb      = create_part(hairHighClimbInfo,      headPivot,      HALF_SIZE),
        hairLowClimb       = create_part(hairLowClimbInfo,       headPivot,      HALF_SIZE),
        hornClimb          = create_part(hornClimbInfo,          headPivot,      HALF_SIZE),

        // head parts
        headPivot          = headPivot,
        head               = create_part(headInfo,               headPivot,      HALF_SIZE),
        helmet             = create_part(helmetInfo,             headPivot,      HALF_SIZE),
        glasses            = create_part(glassesInfo,            headPivot,      HALF_SIZE),
        mask               = create_part(maskInfo,               headPivot,      HALF_SIZE),
        hairLow            = create_part(hairLowInfo,            headPivot,      HALF_SIZE),
        hairHigh           = create_part(hairHighInfo,           headPivot,      HALF_SIZE),
        mouth              = create_part(mouthInfo,              headPivot,      HALF_SIZE),
        mouthHunger        = create_part(mouthHungerInfo,        headPivot,      HALF_SIZE),
        eyes               = create_part(eyesInfo,               headPivot,      HALF_SIZE),
        eyesBlink          = create_part(eyesBlinkInfo,          headPivot,      HALF_SIZE),
        eyesLaser          = create_part(eyesLaserInfo,          headPivot,      HALF_SIZE),
        horns              = create_part(hornsInfo,              headPivot,      HALF_SIZE),
        flameGill          = create_part(flameGillInfo,          headPivot,      HALF_SIZE),

        // body parts
        bodyPivot          = bodyPivot,
        body               = create_part(bodyInfo,               bodyPivot,      HALF_SIZE),
        wing               = create_part(wingInfo,               bodyPivot,      HALF_SIZE),
        wingDown           = create_part(wingDownInfo,           bodyPivot,      HALF_SIZE),
        spikes             = create_part(spikesInfo,             bodyPivot,      HALF_SIZE),

        // weapon parts
        knife              = create_part(knifeInfo,              HALF_SIZE,      HALF_SIZE),
        knifeClaw          = create_part(knifeClawInfo,          HALF_SIZE,      HALF_SIZE),
        rifle              = create_part(rifleInfo,              HALF_SIZE,      HALF_SIZE),
        rifleClaw          = create_part(rifleClawInfo,          HALF_SIZE,      HALF_SIZE),
        shotgun            = create_part(shotgunInfo,            HALF_SIZE,      HALF_SIZE),
        shotgunClaw        = create_part(shotgunClawInfo,        HALF_SIZE,      HALF_SIZE),
        grenade            = create_part(grenadeInfo,            HALF_SIZE,      HALF_SIZE),
        grenadeClaw        = create_part(grenadeClawInfo,        HALF_SIZE,      HALF_SIZE),
        rocket             = create_part(rocketInfo,             HALF_SIZE,      HALF_SIZE),
        rocketClaw         = create_part(rocketClawInfo,         HALF_SIZE,      HALF_SIZE),
        
        // foot parts
        footLeft           = create_part(footLeftInfo,           footLeftPivot,  HALF_SIZE),
        footRight          = create_part(footRightInfo,          footRightPivot, HALF_SIZE),
    }
}
