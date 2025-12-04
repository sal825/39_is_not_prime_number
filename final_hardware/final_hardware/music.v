
//C、F、G
`define NOTE_C4    261.63
`define NOTE_CS4   277.18   // C#4 / Db4
`define NOTE_Db4   277.18
`define NOTE_D4    293.66
`define NOTE_DS4   311.13   // D#4 / Eb4
`define NOTE_Eb4   311.13
`define NOTE_E4    329.63
`define NOTE_F4    349.23
`define NOTE_FS4   369.99   // F#4 / Gb4
`define NOTE_Gb4   369.99
`define NOTE_G4    392.00
`define NOTE_GS4   415.30   // G#4 / Ab4
`define NOTE_Ab4   415.30
`define NOTE_A4    440.00
`define NOTE_AS4   466.16   // A#4 / Bb4
`define NOTE_Bb4   466.16
`define NOTE_B4    493.88

`define NOTE_C3    130.81
`define NOTE_CS3   138.59
`define NOTE_Db3   138.59
`define NOTE_D3    146.83
`define NOTE_DS3   155.56
`define NOTE_Eb3   155.56
`define NOTE_E3    164.81
`define NOTE_F3    174.61
`define NOTE_FS3   185.00
`define NOTE_Gb3   185.00
`define NOTE_G3    196.00
`define NOTE_GS3   207.65
`define NOTE_Ab3   207.65
`define NOTE_A3    220.00
`define NOTE_AS3   233.08
`define NOTE_Bb3   233.08
`define NOTE_B3    246.94

`define NOTE_C5    523.25
`define NOTE_CS5   554.37
`define NOTE_Db5   554.37
`define NOTE_D5    587.33
`define NOTE_DS5   622.25
`define NOTE_Eb5   622.25
`define NOTE_E5    659.25
`define NOTE_F5    698.46
`define NOTE_FS5   739.99
`define NOTE_Gb5   739.99
`define NOTE_G5    783.99
`define NOTE_GS5   830.61
`define NOTE_Ab5   830.61
`define NOTE_A5    880.00
`define NOTE_AS5   932.33
`define NOTE_Bb5   932.33
`define NOTE_B5    987.77

`define NOTE_C6   1046.50
`define NOTE_CS6  1108.73
`define NOTE_D6   1174.66
`define NOTE_E6   1318.51
`define NOTE_F6   1396.91
`define NOTE_G6   1567.98
`define NOTE_A6   1760.00
`define NOTE_B6   1975.53

`define sil   32'd50000000 // slience

module music_wii (
	input [11:0] ibeatNum,
	input en,
	output reg [31:0] toneL,
    output reg [31:0] toneR
);

    always @(*) begin
        toneR = toneL;
    end

    always @(*) begin
        if(en == 1)begin
            case(ibeatNum)
                12'd0: toneL = `NOTE_FS4;  	12'd1: toneL = `NOTE_FS4; // HC (two-beat)
                12'd2: toneL = `NOTE_FS4;  	12'd3: toneL = `NOTE_FS4;
                12'd4: toneL = `NOTE_FS4;	    12'd5: toneL = `NOTE_FS4;
                12'd6: toneL = `NOTE_FS4;  	12'd7: toneL = `NOTE_FS4;
                12'd8: toneL = `NOTE_FS4;	    12'd9: toneL = `NOTE_FS4;
                12'd10: toneL = `NOTE_FS4;	12'd11: toneL = `sil;

                12'd12: toneL = `NOTE_A4;	12'd13: toneL = `NOTE_A4;
                12'd14: toneL = `NOTE_A4;	12'd15: toneL = `NOTE_A4;
                12'd16: toneL = `NOTE_A4;	12'd17: toneL = `sil;
                12'd18: toneL = `NOTE_CS5;	12'd19: toneL = `NOTE_CS5;
                12'd20: toneL = `NOTE_CS5;	12'd21: toneL = `NOTE_CS5;
                12'd22: toneL = `NOTE_CS5;	12'd23: toneL = `sil;

                12'd24: toneL = `sil;	12'd25: toneL = `sil;
                12'd26: toneL = `sil;	12'd27: toneL = `sil;
                12'd28: toneL = `sil;	12'd29: toneL = `sil;
                12'd30: toneL = `NOTE_A4;	12'd31: toneL = `NOTE_A4;
                12'd32: toneL = `NOTE_A4;	    12'd33: toneL = `NOTE_A4; // G (one-beat)
                12'd34: toneL = `NOTE_A4;	    12'd35: toneL = `sil;

                12'd36: toneL = `sil;	    12'd37: toneL = `sil;
                12'd38: toneL = `sil;	    12'd39: toneL = `sil;
                12'd40: toneL = `sil;	    12'd41: toneL = `sil;
                12'd42: toneL = `NOTE_FS4;	    12'd43: toneL = `NOTE_FS4;
                12'd44: toneL = `NOTE_FS4;	    12'd45: toneL = `NOTE_FS4;
                12'd46: toneL = `NOTE_FS4;	    12'd47: toneL = `sil;
//2nd
                12'd48: toneL = `NOTE_D4;	    12'd49: toneL = `NOTE_D4; // B (one-beat)
                12'd50: toneL = `NOTE_D4;	    12'd51: toneL = `NOTE_D4;
                12'd52: toneL = `NOTE_D4;	    12'd53: toneL = `sil;
                12'd54: toneL = `NOTE_D4;	    12'd55: toneL = `NOTE_D4;
                12'd56: toneL = `NOTE_D4;	    12'd57: toneL = `NOTE_D4;
                12'd58: toneL = `NOTE_D4;	    12'd59: toneL = `sil;

                12'd60: toneL = `NOTE_D4;	    12'd61: toneL = `NOTE_D4;
                12'd62: toneL = `NOTE_D4;	    12'd63: toneL = `NOTE_D4;
                12'd64: toneL = `NOTE_D4;	    12'd65: toneL = `sil;
                12'd66: toneL = `sil;	    12'd67: toneL = `sil;
                12'd68: toneL = `sil;	    12'd69: toneL = `sil;
                12'd70: toneL = `sil;	    12'd71: toneL = `sil;

                12'd72: toneL = `sil;	12'd73: toneL = `sil;
                12'd74: toneL = `sil;	12'd75: toneL = `sil;
                12'd76: toneL = `sil;	12'd77: toneL = `sil;
                12'd78: toneL = `sil;	12'd79: toneL = `sil;
                12'd80: toneL = `sil;	12'd81: toneL = `sil;
                12'd82: toneL = `sil;	12'd83: toneL = `sil;

                12'd84: toneL = `sil;	12'd85: toneL = `sil;
                12'd86: toneL = `sil;	12'd87: toneL = `sil;
                12'd88: toneL = `sil;	12'd89: toneL = `sil;
                12'd90: toneL = `NOTE_CS4;	12'd91: toneL = `NOTE_CS4;
                12'd92: toneL = `NOTE_CS4;	12'd93: toneL = `NOTE_CS4;
                12'd94: toneL = `NOTE_CS4;	12'd95: toneL = `sil;
//3rd
                12'd96: toneL = `NOTE_D4;	    12'd97: toneL = `NOTE_D4; // G (one-beat)
                12'd98: toneL = `NOTE_D4; 	12'd99: toneL = `NOTE_D4;
                12'd100: toneL = `NOTE_D4;	12'd101: toneL = `sil;
                12'd102: toneL = `NOTE_FS4;	12'd103: toneL = `NOTE_FS4;
                12'd104: toneL = `NOTE_FS4;	12'd105: toneL = `NOTE_FS4;
                12'd106: toneL = `NOTE_FS4;	12'd107: toneL = `sil;

                12'd108: toneL = `NOTE_A4;	12'd109: toneL = `NOTE_A4;
                12'd110: toneL = `NOTE_A4;	12'd111: toneL = `NOTE_A4;
                12'd112: toneL = `NOTE_A4;	12'd113: toneL = `sil; // B (one-beat)
                12'd114: toneL = `NOTE_CS5;	12'd115: toneL = `NOTE_CS5;
                12'd116: toneL = `NOTE_CS5;	12'd117: toneL = `NOTE_CS5;
                12'd118: toneL = `NOTE_CS5;	12'd119: toneL = `sil;

                12'd120: toneL = `sil;	12'd121: toneL = `sil;
                12'd122: toneL = `sil;	12'd123: toneL = `sil;
                12'd124: toneL = `sil;	12'd125: toneL = `sil;
                12'd126: toneL = `NOTE_A4;	12'd127: toneL = `NOTE_A4;
                12'd128: toneL = `NOTE_A4;	12'd129: toneL = `NOTE_A4;
                12'd130: toneL = `NOTE_A4;	12'd131: toneL = `sil;

                12'd132: toneL = `sil;	12'd133: toneL = `sil;
                12'd134: toneL = `sil;	12'd135: toneL = `sil;
                12'd136: toneL = `sil;	12'd137: toneL = `sil;
                12'd138: toneL = `NOTE_FS4;	12'd139: toneL = `NOTE_FS4;
                12'd140: toneL = `NOTE_FS4;	12'd141: toneL = `NOTE_FS4;
                12'd142: toneL = `NOTE_FS4;	12'd143: toneL = `sil;
//4th
                12'd144: toneL = `NOTE_E5;	12'd145: toneL = `NOTE_E5;
                12'd146: toneL = `NOTE_E5;	12'd147: toneL = `NOTE_E5;
                12'd148: toneL = `NOTE_E5;	12'd149: toneL = `NOTE_E5;
                12'd150: toneL = `NOTE_E5;	12'd151: toneL = `NOTE_E5;
                12'd152: toneL = `NOTE_E5;	12'd153: toneL = `NOTE_E5;
                12'd154: toneL = `NOTE_E5;	12'd155: toneL = `NOTE_E5;

                12'd156: toneL = `NOTE_E5;	12'd157: toneL = `NOTE_E5;
                12'd158: toneL = `NOTE_E5;	12'd159: toneL = `NOTE_E5;
                12'd160: toneL = `NOTE_E5;	12'd161: toneL = `sil;
                12'd162: toneL = `NOTE_DS5;	12'd163: toneL = `NOTE_DS5;
                12'd164: toneL = `NOTE_DS5;	12'd165: toneL = `NOTE_DS5;
                12'd166: toneL = `NOTE_DS5;	12'd167: toneL = `sil;

                12'd168: toneL = `NOTE_D5;	12'd169: toneL = `NOTE_D5;
                12'd170: toneL = `NOTE_D5;	12'd171: toneL = `NOTE_D5;
                12'd172: toneL = `NOTE_D5;	12'd173: toneL = `NOTE_D5;
                12'd174: toneL = `NOTE_D5;	12'd175: toneL = `NOTE_D5;
                12'd176: toneL = `NOTE_D5;	12'd177: toneL = `NOTE_D5;
                12'd178: toneL = `NOTE_D5;	12'd179: toneL = `sil;

                12'd180: toneL = `sil;	12'd181: toneL = `sil;
                12'd182: toneL = `sil;	12'd183: toneL = `sil;
                12'd184: toneL = `sil;	12'd185: toneL = `sil;
                12'd186: toneL = `sil;	12'd187: toneL = `sil;
                12'd188: toneL = `sil;	12'd189: toneL = `sil;
                12'd190: toneL = `sil;	12'd191: toneL = `sil;
//5th
                12'd192: toneL = `NOTE_GS4;	12'd193: toneL = `NOTE_GS4;
                12'd194: toneL = `NOTE_GS4;	12'd195: toneL = `NOTE_GS4;
                12'd196: toneL = `NOTE_GS4;	12'd197: toneL = `sil;
                12'd198: toneL = `sil;	12'd199: toneL = `sil;
                12'd200: toneL = `sil;	12'd201: toneL = `sil;
                12'd202: toneL = `sil;	12'd203: toneL = `sil;

                12'd204: toneL = `NOTE_CS5;	12'd205: toneL = `NOTE_CS5;
                12'd206: toneL = `NOTE_CS5;	12'd207: toneL = `NOTE_CS5;
                12'd208: toneL = `NOTE_CS5;	12'd209: toneL = `sil;
                12'd210: toneL = `NOTE_FS4;	12'd211: toneL = `NOTE_FS4;
                12'd212: toneL = `NOTE_FS4;	12'd213: toneL = `NOTE_FS4;
                12'd214: toneL = `NOTE_FS4;	12'd215: toneL = `sil;

                12'd216: toneL = `sil; 12'd217: toneL = `sil;
                12'd218: toneL = `sil; 12'd219: toneL = `sil;
                12'd220: toneL = `sil; 12'd221: toneL = `sil;
                12'd222: toneL = `NOTE_CS5; 12'd223: toneL = `NOTE_CS5;
                12'd224: toneL = `NOTE_CS5; 12'd225: toneL = `NOTE_CS5;
                12'd226: toneL = `NOTE_CS5; 12'd227: toneL = `sil;

                12'd228: toneL = `sil; 12'd229: toneL = `sil;
                12'd230: toneL = `sil; 12'd231: toneL = `sil;
                12'd232: toneL = `sil; 12'd233: toneL = `sil;
                12'd234: toneL = `NOTE_GS4; 12'd235: toneL = `NOTE_GS4;
                12'd236: toneL = `NOTE_GS4; 12'd237: toneL = `NOTE_GS4;
                12'd238: toneL = `NOTE_GS4; 12'd239: toneL = `sil;
//6th
                12'd240: toneL = `sil; 12'd241: toneL = `sil;
                12'd242: toneL = `sil; 12'd243: toneL = `sil;
                12'd244: toneL = `sil; 12'd245: toneL = `sil;
                12'd246: toneL = `NOTE_CS5; 12'd247: toneL = `NOTE_CS5;
                12'd248: toneL = `NOTE_CS5; 12'd249: toneL = `NOTE_CS5;
                12'd250: toneL = `NOTE_CS5; 12'd251: toneL = `sil;

                12'd252: toneL = `sil; 12'd253: toneL = `sil;
                12'd254: toneL = `sil; 12'd255: toneL = `sil;
                12'd256: toneL = `sil; 12'd257: toneL = `sil;
                12'd258: toneL = `NOTE_G4; 12'd259: toneL = `NOTE_G4;
                12'd260: toneL = `NOTE_G4; 12'd261: toneL = `NOTE_G4;
                12'd262: toneL = `NOTE_G4; 12'd263: toneL = `sil;

                12'd264: toneL = `NOTE_FS4; 12'd265: toneL = `NOTE_FS4;
                12'd266: toneL = `NOTE_FS4; 12'd267: toneL = `NOTE_FS4;
                12'd268: toneL = `NOTE_FS4; 12'd269: toneL = `sil;
                12'd270: toneL = `sil; 12'd271: toneL = `sil;
                12'd272: toneL = `sil; 12'd273: toneL = `sil;
                12'd274: toneL = `sil; 12'd275: toneL = `sil;

                12'd276: toneL = `NOTE_E4; 12'd277: toneL = `NOTE_E4;
                12'd278: toneL = `NOTE_E4; 12'd279: toneL = `NOTE_E4;
                12'd280: toneL = `NOTE_E4; 12'd281: toneL = `sil;
                12'd282: toneL = `sil; 12'd283: toneL = `sil;
                12'd284: toneL = `sil; 12'd285: toneL = `sil;
                12'd286: toneL = `sil; 12'd287: toneL = `sil;
//7th
                12'd288: toneL = `NOTE_C4; 12'd289: toneL = `NOTE_C4;
                12'd290: toneL = `NOTE_C4; 12'd291: toneL = `NOTE_C4;
                12'd292: toneL = `NOTE_C4; 12'd293: toneL = `sil;
                12'd294: toneL = `NOTE_C4; 12'd295: toneL = `NOTE_C4;
                12'd296: toneL = `NOTE_C4; 12'd297: toneL = `NOTE_C4;
                12'd298: toneL = `NOTE_C4; 12'd299: toneL = `sil;

                12'd300: toneL = `NOTE_C4; 12'd301: toneL = `NOTE_C4;
                12'd302: toneL = `NOTE_C4; 12'd303: toneL = `NOTE_C4;
                12'd304: toneL = `NOTE_C4; 12'd305: toneL = `sil;
                12'd306: toneL = `sil; 12'd307: toneL = `sil;
                12'd308: toneL = `sil; 12'd309: toneL = `sil;
                12'd310: toneL = `sil; 12'd311: toneL = `sil;

                12'd312: toneL = `sil; 12'd313: toneL = `sil;
                12'd314: toneL = `sil; 12'd315: toneL = `sil;
                12'd316: toneL = `sil; 12'd317: toneL = `sil;
                12'd318: toneL = `sil; 12'd319: toneL = `sil;
                12'd320: toneL = `sil; 12'd321: toneL = `sil;
                12'd322: toneL = `sil; 12'd323: toneL = `sil;

                12'd324: toneL = `NOTE_C4; 12'd325: toneL = `NOTE_C4;
                12'd326: toneL = `NOTE_C4; 12'd327: toneL = `NOTE_C4;
                12'd328: toneL = `NOTE_C4; 12'd329: toneL = `sil;
                12'd330: toneL = `NOTE_C4; 12'd331: toneL = `NOTE_C4;
                12'd332: toneL = `NOTE_C4; 12'd333: toneL = `NOTE_C4;
                12'd334: toneL = `NOTE_C4; 12'd335: toneL = `sil;
//8th
                12'd336: toneL = `NOTE_C4; 12'd337: toneL = `NOTE_C4;
                12'd338: toneL = `NOTE_C4; 12'd339: toneL = `NOTE_C4;
                12'd340: toneL = `NOTE_C4; 12'd341: toneL = `sil;
                12'd342: toneL = `sil; 12'd343: toneL = `sil;
                12'd344: toneL = `sil; 12'd345: toneL = `sil;
                12'd346: toneL = `sil; 12'd347: toneL = `sil;

                12'd348: toneL = `sil; 12'd349: toneL = `sil;
                12'd350: toneL = `sil; 12'd351: toneL = `sil;
                12'd352: toneL = `sil; 12'd353: toneL = `sil;
                12'd354: toneL = `sil; 12'd355: toneL = `sil;
                12'd356: toneL = `sil; 12'd357: toneL = `sil;
                12'd358: toneL = `sil; 12'd359: toneL = `sil;

                12'd360: toneL = `NOTE_E5; 12'd361: toneL = `NOTE_E5;
                12'd362: toneL = `NOTE_E5; 12'd363: toneL = `NOTE_E5;
                12'd364: toneL = `NOTE_E5; 12'd365: toneL = `NOTE_E5;
                12'd366: toneL = `NOTE_E5; 12'd367: toneL = `NOTE_E5;
                12'd368: toneL = `NOTE_E5; 12'd369: toneL = `NOTE_E5;
                12'd370: toneL = `NOTE_E5; 12'd371: toneL = `sil;

                12'd372: toneL = `NOTE_DS5; 12'd373: toneL = `NOTE_DS5;
                12'd374: toneL = `NOTE_DS5; 12'd375: toneL = `NOTE_DS5;
                12'd376: toneL = `NOTE_DS5; 12'd377: toneL = `NOTE_DS5;
                12'd378: toneL = `NOTE_DS5; 12'd379: toneL = `NOTE_DS5;
                12'd380: toneL = `NOTE_DS5; 12'd381: toneL = `NOTE_DS5;
                12'd382: toneL = `NOTE_DS5; 12'd383: toneL = `sil;
//9th
                12'd384: toneL = `NOTE_D5; 12'd385: toneL = `NOTE_D5;
                12'd386: toneL = `NOTE_D5; 12'd387: toneL = `NOTE_D5;
                12'd388: toneL = `NOTE_D5; 12'd389: toneL = `NOTE_D5;
                12'd390: toneL = `NOTE_D5; 12'd391: toneL = `NOTE_D5;
                12'd392: toneL = `NOTE_D5; 12'd393: toneL = `NOTE_D5;
                12'd394: toneL = `NOTE_D5; 12'd395: toneL = `sil;

                12'd396: toneL = `NOTE_A4; 12'd397: toneL = `NOTE_A4;
                12'd398: toneL = `NOTE_A4; 12'd399: toneL = `NOTE_A4;
                12'd400: toneL = `NOTE_A4; 12'd401: toneL = `sil;
                12'd402: toneL = `NOTE_CS5; 12'd403: toneL = `NOTE_CS5;
                12'd404: toneL = `NOTE_CS5; 12'd405: toneL = `NOTE_CS5;
                12'd406: toneL = `NOTE_CS5; 12'd407: toneL = `sil;

                12'd408: toneL = `sil; 12'd409: toneL = `sil;
                12'd410: toneL = `sil; 12'd411: toneL = `sil;
                12'd412: toneL = `sil; 12'd413: toneL = `sil;
                12'd414: toneL = `NOTE_A4; 12'd415: toneL = `NOTE_A4;
                12'd416: toneL = `NOTE_A4; 12'd417: toneL = `NOTE_A4;
                12'd418: toneL = `NOTE_A4; 12'd419: toneL = `sil;

                12'd420: toneL = `sil; 12'd421: toneL = `sil;
                12'd422: toneL = `sil; 12'd423: toneL = `sil;
                12'd424: toneL = `sil; 12'd425: toneL = `sil;
                12'd426: toneL = `NOTE_FS4; 12'd427: toneL = `NOTE_FS4;
                12'd428: toneL = `NOTE_FS4; 12'd429: toneL = `NOTE_FS4;
                12'd430: toneL = `NOTE_FS4; 12'd431: toneL = `sil;
//10th
                12'd432: toneL = `NOTE_E4; 12'd433: toneL = `NOTE_E4;
                12'd434: toneL = `NOTE_E4; 12'd435: toneL = `NOTE_E4;
                12'd436: toneL = `NOTE_E4; 12'd437: toneL = `sil;
                12'd438: toneL = `NOTE_E4; 12'd439: toneL = `NOTE_E4;
                12'd440: toneL = `NOTE_E4; 12'd441: toneL = `NOTE_E4;
                12'd442: toneL = `NOTE_E4; 12'd443: toneL = `sil;

                12'd444: toneL = `NOTE_E4; 12'd445: toneL = `NOTE_E4;
                12'd446: toneL = `NOTE_E4; 12'd447: toneL = `NOTE_E4;
                12'd448: toneL = `NOTE_E4; 12'd449: toneL = `sil;
                12'd450: toneL = `sil; 12'd451: toneL = `sil;
                12'd452: toneL = `sil; 12'd453: toneL = `sil;
                12'd454: toneL = `sil; 12'd455: toneL = `sil;

                12'd456: toneL = `NOTE_E5; 12'd457: toneL = `NOTE_E5;
                12'd458: toneL = `NOTE_E5; 12'd459: toneL = `NOTE_E5;
                12'd460: toneL = `NOTE_E5; 12'd461: toneL = `sil;
                12'd462: toneL = `NOTE_E5; 12'd463: toneL = `NOTE_E5;
                12'd464: toneL = `NOTE_E5; 12'd465: toneL = `NOTE_E5;
                12'd466: toneL = `NOTE_E5; 12'd467: toneL = `sil;

                12'd468: toneL = `NOTE_E5; 12'd469: toneL = `NOTE_E5;
                12'd470: toneL = `NOTE_E5; 12'd471: toneL = `NOTE_E5;
                12'd472: toneL = `NOTE_E5; 12'd473: toneL = `sil;
                12'd474: toneL = `sil; 12'd475: toneL = `sil;
                12'd476: toneL = `sil; 12'd477: toneL = `sil;
                12'd478: toneL = `sil; 12'd479: toneL = `sil;
//11th
                12'd480: toneL = `sil; 12'd481: toneL = `sil;
                12'd482: toneL = `sil; 12'd483: toneL = `sil;
                12'd484: toneL = `sil; 12'd485: toneL = `sil;
                12'd486: toneL = `NOTE_FS4; 12'd487: toneL = `NOTE_FS4;
                12'd488: toneL = `NOTE_FS4; 12'd489: toneL = `NOTE_FS4;
                12'd490: toneL = `NOTE_FS4; 12'd491: toneL = `sil;

                12'd492: toneL = `NOTE_A4; 12'd493: toneL = `NOTE_A4;
                12'd494: toneL = `NOTE_A4; 12'd495: toneL = `NOTE_A4;
                12'd496: toneL = `NOTE_A4; 12'd497: toneL = `sil;
                12'd498: toneL = `NOTE_CS5; 12'd499: toneL = `NOTE_CS5;
                12'd500: toneL = `NOTE_CS5; 12'd501: toneL = `NOTE_CS5;
                12'd502: toneL = `NOTE_CS5; 12'd503: toneL = `sil;

                12'd504: toneL = `sil; 12'd505: toneL = `sil;
                12'd506: toneL = `sil; 12'd507: toneL = `sil;
                12'd508: toneL = `sil; 12'd509: toneL = `sil;
                12'd510: toneL = `NOTE_A4; 12'd511: toneL = `NOTE_A4;
                12'd512: toneL = `NOTE_A4; 12'd513: toneL = `NOTE_A4;
                12'd514: toneL = `NOTE_A4; 12'd515: toneL = `NOTE_A4;

                12'd516: toneL = `sil; 12'd517: toneL = `sil;
                12'd518: toneL = `sil; 12'd519: toneL = `sil;
                12'd520: toneL = `sil; 12'd521: toneL = `sil;
                12'd522: toneL = `NOTE_FS4; 12'd523: toneL = `NOTE_FS4;
                12'd524: toneL = `NOTE_FS4; 12'd525: toneL = `NOTE_FS4;
                12'd526: toneL = `NOTE_FS4; 12'd527: toneL = `sil;
//12th
                12'd528: toneL = `NOTE_E5; 12'd529: toneL = `NOTE_E5;
                12'd530: toneL = `NOTE_E5; 12'd531: toneL = `NOTE_E5;
                12'd532: toneL = `NOTE_E5; 12'd533: toneL = `NOTE_E5;
                12'd534: toneL = `NOTE_E5; 12'd535: toneL = `NOTE_E5;
                12'd536: toneL = `NOTE_E5; 12'd537: toneL = `NOTE_E5;
                12'd538: toneL = `NOTE_E5; 12'd539: toneL = `NOTE_E5;
                
                12'd540: toneL = `NOTE_E5; 12'd541: toneL = `NOTE_E5;
                12'd542: toneL = `NOTE_E5; 12'd543: toneL = `NOTE_E5;
                12'd544: toneL = `NOTE_E5; 12'd545: toneL = `NOTE_E5;
                12'd546: toneL = `NOTE_E5; 12'd547: toneL = `NOTE_E5;
                12'd548: toneL = `NOTE_E5; 12'd549: toneL = `NOTE_E5;
                12'd550: toneL = `NOTE_E5; 12'd551: toneL = `sil;
                
                12'd552: toneL = `NOTE_D5; 12'd553: toneL = `NOTE_D5;
                12'd554: toneL = `NOTE_D5; 12'd555: toneL = `NOTE_D5;
                12'd556: toneL = `NOTE_D5; 12'd557: toneL = `NOTE_D5;
                12'd558: toneL = `NOTE_D5; 12'd559: toneL = `NOTE_D5;
                12'd560: toneL = `NOTE_D5; 12'd561: toneL = `NOTE_D5;
                12'd562: toneL = `NOTE_D5; 12'd563: toneL = `sil;

                12'd564: toneL = `sil; 12'd565: toneL = `sil;
                12'd566: toneL = `sil; 12'd567: toneL = `sil;
                12'd568: toneL = `sil; 12'd569: toneL = `sil;
                12'd570: toneL = `sil; 12'd571: toneL = `sil;
                12'd572: toneL = `sil; 12'd573: toneL = `sil;
                12'd574: toneL = `sil; 12'd575: toneL = `sil;
//13th
                12'd576: toneL = `NOTE_B5; 12'd577: toneL = `NOTE_B5;
                12'd578: toneL = `NOTE_B5; 12'd579: toneL = `NOTE_B5;
                12'd580: toneL = `NOTE_B5; 12'd581: toneL = `NOTE_B5;
                12'd582: toneL = `NOTE_G5; 12'd583: toneL = `NOTE_G5;
                12'd584: toneL = `NOTE_G5; 12'd585: toneL = `NOTE_G5;
                12'd586: toneL = `NOTE_G5; 12'd587: toneL = `NOTE_G5;

                12'd588: toneL = `NOTE_D5; 12'd589: toneL = `NOTE_D5;
                12'd590: toneL = `NOTE_D5; 12'd591: toneL = `NOTE_D5;
                12'd592: toneL = `NOTE_D5; 12'd593: toneL = `NOTE_D5;
                12'd594: toneL = `NOTE_CS5; 12'd595: toneL = `NOTE_CS5;
                12'd596: toneL = `NOTE_CS5; 12'd597: toneL = `NOTE_CS5;
                12'd598: toneL = `NOTE_CS5; 12'd599: toneL = `NOTE_CS5;

                12'd600: toneL = `NOTE_CS5; 12'd601: toneL = `NOTE_CS5;
                12'd602: toneL = `NOTE_CS5; 12'd603: toneL = `NOTE_CS5;
                12'd604: toneL = `NOTE_CS5; 12'd605: toneL = `NOTE_CS5;
                12'd606: toneL = `NOTE_B5; 12'd607: toneL = `NOTE_B5;
                12'd608: toneL = `NOTE_B5; 12'd609: toneL = `NOTE_B5;
                12'd610: toneL = `NOTE_B5; 12'd611: toneL = `NOTE_B5;

                12'd612: toneL = `NOTE_G5; 12'd613: toneL = `NOTE_G5;
                12'd614: toneL = `NOTE_G5; 12'd615: toneL = `NOTE_G5;
                12'd616: toneL = `NOTE_G5; 12'd617: toneL = `NOTE_G5;
                12'd618: toneL = `NOTE_CS5; 12'd619: toneL = `NOTE_CS5;
                12'd620: toneL = `NOTE_CS5; 12'd621: toneL = `NOTE_CS5;
                12'd622: toneL = `NOTE_CS5; 12'd623: toneL = `sil;
//14th
                12'd624: toneL = `NOTE_A5; 12'd625: toneL = `NOTE_A5;
                12'd626: toneL = `NOTE_A5; 12'd627: toneL = `NOTE_A5;
                12'd628: toneL = `NOTE_A5; 12'd629: toneL = `NOTE_A5;
                12'd630: toneL = `NOTE_FS5; 12'd631: toneL = `NOTE_FS5;
                12'd632: toneL = `NOTE_FS5; 12'd633: toneL = `NOTE_FS5;
                12'd634: toneL = `NOTE_FS5; 12'd635: toneL = `NOTE_FS5;

                12'd636: toneL = `NOTE_C5; 12'd637: toneL = `NOTE_C5;
                12'd638: toneL = `NOTE_C5; 12'd639: toneL = `NOTE_C5;
                12'd640: toneL = `NOTE_C5; 12'd641: toneL = `NOTE_C5;
                12'd642: toneL = `NOTE_B4; 12'd643: toneL = `NOTE_B4;
                12'd644: toneL = `NOTE_B4; 12'd645: toneL = `NOTE_B4;
                12'd646: toneL = `NOTE_B4; 12'd647: toneL = `NOTE_B4;

                12'd648: toneL = `NOTE_B4; 12'd649: toneL = `NOTE_B4;
                12'd650: toneL = `NOTE_B4; 12'd651: toneL = `NOTE_B4;
                12'd652: toneL = `NOTE_B4; 12'd653: toneL = `NOTE_B4;
                12'd654: toneL = `NOTE_F5; 12'd655: toneL = `NOTE_F5;
                12'd656: toneL = `NOTE_F5; 12'd657: toneL = `NOTE_F5;
                12'd658: toneL = `NOTE_F5; 12'd659: toneL = `NOTE_F5;

                12'd660: toneL = `NOTE_D5; 12'd661: toneL = `NOTE_D5;
                12'd662: toneL = `NOTE_D5; 12'd663: toneL = `NOTE_D5;
                12'd664: toneL = `NOTE_D5; 12'd665: toneL = `NOTE_D5;
                12'd666: toneL = `NOTE_B4; 12'd667: toneL = `NOTE_B4;
                12'd668: toneL = `NOTE_B4; 12'd669: toneL = `NOTE_B4;
                12'd670: toneL = `NOTE_B4; 12'd671: toneL = `sil;
//15th
                12'd672: toneL = `NOTE_E5; 12'd673: toneL = `NOTE_E5;
                12'd674: toneL = `NOTE_E5; 12'd675: toneL = `NOTE_E5;
                12'd676: toneL = `NOTE_E5; 12'd677: toneL = `sil;
                12'd678: toneL = `NOTE_E5; 12'd679: toneL = `NOTE_E5;
                12'd680: toneL = `NOTE_E5; 12'd681: toneL = `NOTE_E5;
                12'd682: toneL = `NOTE_E5; 12'd683: toneL = `sil;

                12'd684: toneL = `NOTE_E5; 12'd685: toneL = `NOTE_E5;
                12'd686: toneL = `NOTE_E5; 12'd687: toneL = `NOTE_E5;
                12'd688: toneL = `NOTE_E5; 12'd689: toneL = `sil;
                12'd690: toneL = `sil; 12'd691: toneL = `sil;
                12'd692: toneL = `sil; 12'd693: toneL = `sil;
                12'd694: toneL = `sil; 12'd695: toneL = `sil;

                12'd696: toneL = `sil; 12'd697: toneL = `sil;
                12'd698: toneL = `sil; 12'd699: toneL = `sil;
                12'd700: toneL = `sil; 12'd701: toneL = `sil;
                12'd702: toneL = `sil; 12'd703: toneL = `sil;
                12'd704: toneL = `sil; 12'd705: toneL = `sil;
                12'd706: toneL = `sil; 12'd707: toneL = `sil;

                12'd708: toneL = `sil; 12'd709: toneL = `sil;
                12'd710: toneL = `sil; 12'd711: toneL = `sil;
                12'd712: toneL = `sil; 12'd713: toneL = `sil;
                12'd714: toneL = `NOTE_AS4; 12'd715: toneL = `NOTE_AS4;
                12'd716: toneL = `NOTE_AS4; 12'd717: toneL = `NOTE_AS4;
                12'd718: toneL = `NOTE_AS4; 12'd719: toneL = `NOTE_AS4;
//16th
                12'd720: toneL = `NOTE_B4; 12'd721: toneL = `NOTE_B4;
                12'd722: toneL = `NOTE_B4; 12'd723: toneL = `NOTE_B4;
                12'd724: toneL = `NOTE_B4; 12'd725: toneL = `sil;
                12'd726: toneL = `NOTE_CS5; 12'd727: toneL = `NOTE_CS5;
                12'd728: toneL = `NOTE_CS5; 12'd729: toneL = `NOTE_CS5;
                12'd730: toneL = `NOTE_CS5; 12'd731: toneL = `NOTE_CS5;
                
                12'd732: toneL = `NOTE_D5; 12'd733: toneL = `NOTE_D5;
                12'd734: toneL = `NOTE_D5; 12'd735: toneL = `NOTE_D5;
                12'd736: toneL = `NOTE_D5; 12'd737: toneL = `sil;
                12'd738: toneL = `NOTE_FS5; 12'd739: toneL = `NOTE_FS5;
                12'd740: toneL = `NOTE_FS5; 12'd741: toneL = `NOTE_FS5;
                12'd742: toneL = `NOTE_FS5; 12'd743: toneL = `NOTE_FS5;

                12'd744: toneL = `NOTE_A5; 12'd745: toneL = `NOTE_A5;
                12'd746: toneL = `NOTE_A5; 12'd747: toneL = `NOTE_A5;
                12'd748: toneL = `NOTE_A5; 12'd749: toneL = `sil;
                12'd750: toneL = `sil; 12'd751: toneL = `sil;
                12'd752: toneL = `sil; 12'd753: toneL = `sil;
                12'd754: toneL = `sil; 12'd755: toneL = `sil;

                12'd756: toneL = `sil; 12'd757: toneL = `sil;
                12'd758: toneL = `sil; 12'd759: toneL = `sil;
                12'd760: toneL = `sil; 12'd761: toneL = `sil;
                12'd762: toneL = `sil; 12'd763: toneL = `sil;
                12'd764: toneL = `sil; 12'd765: toneL = `sil;
                12'd766: toneL = `sil; 12'd767: toneL = `sil;
//17th
                12'd768: toneL = `sil; 12'd769: toneL = `sil;
                12'd770: toneL = `sil; 12'd771: toneL = `sil;
                12'd772: toneL = `sil; 12'd773: toneL = `sil;
                12'd774: toneL = `sil; 12'd775: toneL = `sil;
                12'd776: toneL = `sil; 12'd777: toneL = `sil;
                12'd778: toneL = `sil; 12'd779: toneL = `sil;

                12'd780: toneL = `sil; 12'd781: toneL = `sil;
                12'd782: toneL = `sil; 12'd783: toneL = `sil;
                12'd784: toneL = `sil; 12'd785: toneL = `sil;
                12'd786: toneL = `sil; 12'd787: toneL = `sil;
                12'd788: toneL = `sil; 12'd789: toneL = `sil;
                12'd790: toneL = `sil; 12'd791: toneL = `sil;

                12'd792: toneL = `NOTE_A4; 12'd793: toneL = `NOTE_A4;
                12'd794: toneL = `NOTE_A4; 12'd795: toneL = `NOTE_A4;
                12'd796: toneL = `NOTE_A4; 12'd797: toneL = `NOTE_A4;
                12'd798: toneL = `NOTE_A4; 12'd799: toneL = `NOTE_A4;
                12'd800: toneL = `NOTE_A4; 12'd801: toneL = `NOTE_A4;
                12'd802: toneL = `NOTE_A4; 12'd803: toneL = `NOTE_A4;

                12'd804: toneL = `NOTE_AS4; 12'd805: toneL = `NOTE_AS4;
                12'd806: toneL = `NOTE_AS4; 12'd807: toneL = `NOTE_AS4;
                12'd808: toneL = `NOTE_AS4; 12'd809: toneL = `NOTE_AS4;
                12'd810: toneL = `NOTE_AS4; 12'd811: toneL = `NOTE_AS4;
                12'd812: toneL = `NOTE_AS4; 12'd813: toneL = `NOTE_AS4;
                12'd814: toneL = `NOTE_AS4; 12'd815: toneL = `NOTE_AS4;
//18th
                12'd816: toneL = `NOTE_B4; 12'd817: toneL = `NOTE_B4;
                12'd818: toneL = `NOTE_B4; 12'd819: toneL = `NOTE_B4;
                12'd820: toneL = `NOTE_B4; 12'd821: toneL = `NOTE_B4;
                12'd822: toneL = `NOTE_B4; 12'd823: toneL = `NOTE_B4;
                12'd824: toneL = `NOTE_B4; 12'd825: toneL = `NOTE_B4;
                12'd826: toneL = `NOTE_B4; 12'd827: toneL = `NOTE_B4;

                12'd828: toneL = `NOTE_B4; 12'd829: toneL = `NOTE_B4;
                12'd830: toneL = `NOTE_B4; 12'd831: toneL = `NOTE_B4;
                12'd832: toneL = `NOTE_B4; 12'd833: toneL = `NOTE_B4;
                12'd834: toneL = `NOTE_AS4; 12'd835: toneL = `NOTE_AS4;
                12'd836: toneL = `NOTE_AS4; 12'd837: toneL = `NOTE_AS4;
                12'd838: toneL = `NOTE_AS4; 12'd839: toneL = `NOTE_AS4;

                12'd840: toneL = `NOTE_B4; 12'd841: toneL = `NOTE_B4;
                12'd842: toneL = `NOTE_B4; 12'd843: toneL = `NOTE_B4;
                12'd844: toneL = `NOTE_B4; 12'd845: toneL = `NOTE_B4;
                12'd846: toneL = `NOTE_B4; 12'd847: toneL = `NOTE_B4;
                12'd848: toneL = `NOTE_B4; 12'd849: toneL = `NOTE_B4;
                12'd850: toneL = `NOTE_B4; 12'd851: toneL = `NOTE_B4;

                12'd852: toneL = `NOTE_B4; 12'd853: toneL = `NOTE_B4;
                12'd854: toneL = `NOTE_B4; 12'd855: toneL = `NOTE_B4;
                12'd856: toneL = `NOTE_B4; 12'd857: toneL = `NOTE_B4;
                12'd858: toneL = `NOTE_B4; 12'd859: toneL = `NOTE_B4;
                12'd860: toneL = `NOTE_B4; 12'd861: toneL = `NOTE_B4;
                12'd862: toneL = `NOTE_B4; 12'd863: toneL = `NOTE_B4;
//19th
                12'd864: toneL = `NOTE_B4; 12'd865: toneL = `NOTE_B4;
                12'd866: toneL = `NOTE_B4; 12'd867: toneL = `NOTE_B4;
                12'd868: toneL = `NOTE_B4; 12'd869: toneL = `NOTE_B4;
                12'd870: toneL = `NOTE_B4; 12'd871: toneL = `NOTE_B4;
                12'd872: toneL = `NOTE_B4; 12'd873: toneL = `NOTE_B4;
                12'd874: toneL = `NOTE_B4; 12'd875: toneL = `sil;

                12'd876: toneL = `NOTE_A4; 12'd877: toneL = `NOTE_A4;
                12'd878: toneL = `NOTE_A4; 12'd879: toneL = `NOTE_A4;
                12'd880: toneL = `NOTE_A4; 12'd881: toneL = `NOTE_A4;
                12'd882: toneL = `NOTE_AS4; 12'd883: toneL = `NOTE_AS4;
                12'd884: toneL = `NOTE_AS4; 12'd885: toneL = `NOTE_AS4;
                12'd886: toneL = `NOTE_AS4; 12'd887: toneL = `NOTE_AS4;

                12'd888: toneL = `NOTE_B4; 12'd889: toneL = `NOTE_B4;
                12'd890: toneL = `NOTE_B4; 12'd891: toneL = `NOTE_B4;
                12'd892: toneL = `NOTE_B4; 12'd893: toneL = `NOTE_B4;
                12'd894: toneL = `NOTE_FS5; 12'd895: toneL = `NOTE_FS5;
                12'd896: toneL = `NOTE_FS5; 12'd897: toneL = `NOTE_FS5;
                12'd898: toneL = `NOTE_FS5; 12'd899: toneL = `NOTE_FS5;

                12'd900: toneL = `NOTE_FS5; 12'd901: toneL = `NOTE_FS5;
                12'd902: toneL = `NOTE_FS5; 12'd903: toneL = `NOTE_FS5;
                12'd904: toneL = `NOTE_FS5; 12'd905: toneL = `NOTE_FS5;
                12'd906: toneL = `NOTE_CS5; 12'd907: toneL = `NOTE_CS5;
                12'd908: toneL = `NOTE_CS5; 12'd909: toneL = `NOTE_CS5;
                12'd910: toneL = `NOTE_CS5; 12'd911: toneL = `NOTE_CS5;
//20th
                12'd912: toneL = `NOTE_B4; 12'd913: toneL = `NOTE_B4;
                12'd914: toneL = `NOTE_B4; 12'd915: toneL = `NOTE_B4;
                12'd916: toneL = `NOTE_B4; 12'd917: toneL = `NOTE_B4;
                12'd918: toneL = `NOTE_B4; 12'd919: toneL = `NOTE_B4;
                12'd920: toneL = `NOTE_B4; 12'd921: toneL = `NOTE_B4;
                12'd922: toneL = `NOTE_B4; 12'd923: toneL = `NOTE_B4;

                12'd924: toneL = `NOTE_B4; 12'd925: toneL = `NOTE_B4;
                12'd926: toneL = `NOTE_B4; 12'd927: toneL = `NOTE_B4;
                12'd928: toneL = `NOTE_B4; 12'd929: toneL = `NOTE_B4;
                12'd930: toneL = `NOTE_AS4; 12'd931: toneL = `NOTE_AS4;
                12'd932: toneL = `NOTE_AS4; 12'd933: toneL = `NOTE_AS4;
                12'd934: toneL = `NOTE_AS4; 12'd935: toneL = `NOTE_AS4;

                12'd936: toneL = `NOTE_B4; 12'd937: toneL = `NOTE_B4;
                12'd938: toneL = `NOTE_B4; 12'd939: toneL = `NOTE_B4;
                12'd940: toneL = `NOTE_B4; 12'd941: toneL = `NOTE_B4;
                12'd942: toneL = `NOTE_B4; 12'd943: toneL = `NOTE_B4;
                12'd944: toneL = `NOTE_B4; 12'd945: toneL = `NOTE_B4;
                12'd946: toneL = `NOTE_B4; 12'd947: toneL = `NOTE_B4;

                12'd948: toneL = `NOTE_B4; 12'd949: toneL = `NOTE_B4;
                12'd950: toneL = `NOTE_B4; 12'd951: toneL = `NOTE_B4;
                12'd952: toneL = `NOTE_B4; 12'd953: toneL = `NOTE_B4;
                12'd954: toneL = `NOTE_B4; 12'd955: toneL = `NOTE_B4;
                12'd956: toneL = `NOTE_B4; 12'd957: toneL = `NOTE_B4;
                12'd958: toneL = `NOTE_B4; 12'd959: toneL = `NOTE_B4;
//21st
                12'd960: toneL = `NOTE_B4; 12'd961: toneL = `NOTE_B4;
                12'd962: toneL = `NOTE_B4; 12'd963: toneL = `NOTE_B4;
                12'd964: toneL = `NOTE_B4; 12'd965: toneL = `NOTE_B4;
                12'd966: toneL = `NOTE_B4; 12'd967: toneL = `NOTE_B4;
                12'd968: toneL = `NOTE_B4; 12'd969: toneL = `NOTE_B4;
                12'd970: toneL = `NOTE_B4; 12'd971: toneL = `NOTE_B4;

                12'd972: toneL = `NOTE_B4; 12'd973: toneL = `NOTE_B4;
                12'd974: toneL = `NOTE_B4; 12'd975: toneL = `NOTE_B4;
                12'd976: toneL = `NOTE_B4; 12'd977: toneL = `NOTE_B4;
                12'd978: toneL = `NOTE_B4; 12'd979: toneL = `NOTE_B4;
                12'd980: toneL = `NOTE_B4; 12'd981: toneL = `NOTE_B4;
                12'd982: toneL = `NOTE_B4; 12'd983: toneL = `sil;

                12'd984: toneL = `NOTE_B4; 12'd985: toneL = `NOTE_B4;
                12'd986: toneL = `NOTE_B4; 12'd987: toneL = `NOTE_B4;
                12'd988: toneL = `NOTE_B4; 12'd989: toneL = `NOTE_B4;
                12'd990: toneL = `NOTE_B4; 12'd991: toneL = `NOTE_B4;
                12'd992: toneL = `NOTE_B4; 12'd993: toneL = `NOTE_B4;
                12'd994: toneL = `NOTE_B4; 12'd995: toneL = `NOTE_B4;

                12'd996: toneL = `NOTE_C5; 12'd997: toneL = `NOTE_C5;
                12'd998: toneL = `NOTE_C5; 12'd999: toneL = `NOTE_C5;
                12'd1000: toneL = `NOTE_C5; 12'd1001: toneL = `NOTE_C5;
                12'd1002: toneL = `NOTE_C5; 12'd1003: toneL = `NOTE_C5;
                12'd1004: toneL = `NOTE_C5; 12'd1005: toneL = `NOTE_C5;
                12'd1006: toneL = `NOTE_C5; 12'd1007: toneL = `NOTE_C5;
//22nd
                12'd1008: toneL = `NOTE_CS5; 12'd1009: toneL = `NOTE_CS5;
                12'd1010: toneL = `NOTE_CS5; 12'd1011: toneL = `NOTE_CS5;
                12'd1012: toneL = `NOTE_CS5; 12'd1013: toneL = `NOTE_CS5;
                12'd1014: toneL = `NOTE_CS5; 12'd1015: toneL = `NOTE_CS5;
                12'd1016: toneL = `NOTE_CS5; 12'd1017: toneL = `NOTE_CS5;
                12'd1018: toneL = `NOTE_CS5; 12'd1019: toneL = `NOTE_CS5;

                12'd1020: toneL = `NOTE_CS5; 12'd1021: toneL = `NOTE_CS5;
                12'd1022: toneL = `NOTE_CS5; 12'd1023: toneL = `NOTE_CS5;
                12'd1024: toneL = `NOTE_CS5; 12'd1025: toneL = `NOTE_CS5;
                12'd1026: toneL = `NOTE_C5; 12'd1027: toneL = `NOTE_C5;
                12'd1028: toneL = `NOTE_C5; 12'd1029: toneL = `NOTE_C5;
                12'd1030: toneL = `NOTE_C5; 12'd1031: toneL = `NOTE_C5;

                12'd1032: toneL = `NOTE_CS5; 12'd1033: toneL = `NOTE_CS5;
                12'd1034: toneL = `NOTE_CS5; 12'd1035: toneL = `NOTE_CS5;
                12'd1036: toneL = `NOTE_CS5; 12'd1037: toneL = `NOTE_CS5;
                12'd1038: toneL = `NOTE_CS5; 12'd1039: toneL = `NOTE_CS5;
                12'd1040: toneL = `NOTE_CS5; 12'd1041: toneL = `NOTE_CS5;
                12'd1042: toneL = `NOTE_CS5; 12'd1043: toneL = `NOTE_CS5;

                12'd1044: toneL = `NOTE_CS5; 12'd1045: toneL = `NOTE_CS5;
                12'd1046: toneL = `NOTE_CS5; 12'd1047: toneL = `NOTE_CS5;
                12'd1048: toneL = `NOTE_CS5; 12'd1049: toneL = `NOTE_CS5;
                12'd1050: toneL = `NOTE_CS5; 12'd1051: toneL = `NOTE_CS5;
                12'd1052: toneL = `NOTE_CS5; 12'd1053: toneL = `NOTE_CS5;
                12'd1054: toneL = `NOTE_CS5; 12'd1055: toneL = `NOTE_CS5;
//23rd
                12'd1056: toneL = `NOTE_CS5; 12'd1057: toneL = `NOTE_CS5;
                12'd1058: toneL = `NOTE_CS5; 12'd1059: toneL = `NOTE_CS5;
                12'd1060: toneL = `NOTE_CS5; 12'd1061: toneL = `NOTE_CS5;
                12'd1062: toneL = `NOTE_CS5; 12'd1063: toneL = `NOTE_CS5;
                12'd1064: toneL = `NOTE_CS5; 12'd1065: toneL = `NOTE_CS5;
                12'd1066: toneL = `NOTE_CS5; 12'd1067: toneL = `sil;

                12'd1068: toneL = `NOTE_CS5; 12'd1069: toneL = `NOTE_CS5;
                12'd1070: toneL = `NOTE_CS5; 12'd1071: toneL = `NOTE_CS5;
                12'd1072: toneL = `NOTE_CS5; 12'd1073: toneL = `NOTE_CS5;
                12'd1074: toneL = `NOTE_C5; 12'd1075: toneL = `NOTE_C5;
                12'd1076: toneL = `NOTE_C5; 12'd1077: toneL = `NOTE_C5;
                12'd1078: toneL = `NOTE_C5; 12'd1079: toneL = `NOTE_C5;

                12'd1080: toneL = `NOTE_CS5; 12'd1081: toneL = `NOTE_CS5;
                12'd1082: toneL = `NOTE_CS5; 12'd1083: toneL = `NOTE_CS5;
                12'd1084: toneL = `NOTE_CS5; 12'd1085: toneL = `NOTE_CS5;
                12'd1086: toneL = `NOTE_GS5; 12'd1087: toneL = `NOTE_GS5;
                12'd1088: toneL = `NOTE_GS5; 12'd1089: toneL = `NOTE_GS5;
                12'd1090: toneL = `NOTE_GS5; 12'd1091: toneL = `NOTE_GS5;

                12'd1092: toneL = `NOTE_GS5; 12'd1093: toneL = `NOTE_GS5;
                12'd1094: toneL = `NOTE_GS5; 12'd1095: toneL = `NOTE_GS5;
                12'd1096: toneL = `NOTE_GS5; 12'd1097: toneL = `NOTE_GS5;
                12'd1098: toneL = `NOTE_DS5; 12'd1099: toneL = `NOTE_DS5;
                12'd1100: toneL = `NOTE_DS5; 12'd1101: toneL = `NOTE_DS5;
                12'd1102: toneL = `NOTE_DS5; 12'd1103: toneL = `NOTE_DS5;
//24th
                12'd1104: toneL = `NOTE_CS5; 12'd1105: toneL = `NOTE_CS5;
                12'd1106: toneL = `NOTE_CS5; 12'd1107: toneL = `NOTE_CS5;
                12'd1108: toneL = `NOTE_CS5; 12'd1109: toneL = `NOTE_CS5;
                12'd1110: toneL = `NOTE_CS5; 12'd1111: toneL = `NOTE_CS5;
                12'd1112: toneL = `NOTE_CS5; 12'd1113: toneL = `NOTE_CS5;
                12'd1114: toneL = `NOTE_CS5; 12'd1115: toneL = `NOTE_CS5;

                12'd1116: toneL = `NOTE_CS5; 12'd1117: toneL = `NOTE_CS5;
                12'd1118: toneL = `NOTE_CS5; 12'd1119: toneL = `NOTE_CS5;
                12'd1120: toneL = `NOTE_CS5; 12'd1121: toneL = `NOTE_CS5;
                12'd1122: toneL = `NOTE_DS5; 12'd1123: toneL = `NOTE_DS5;
                12'd1124: toneL = `NOTE_DS5; 12'd1125: toneL = `NOTE_DS5;
                12'd1126: toneL = `NOTE_DS5; 12'd1127: toneL = `NOTE_DS5;

                12'd1128: toneL = `NOTE_B4; 12'd1129: toneL = `NOTE_B4;
                12'd1130: toneL = `NOTE_B4; 12'd1131: toneL = `NOTE_B4;
                12'd1132: toneL = `NOTE_B4; 12'd1133: toneL = `NOTE_B4;
                12'd1134: toneL = `NOTE_B4; 12'd1135: toneL = `NOTE_B4;
                12'd1136: toneL = `NOTE_B4; 12'd1137: toneL = `NOTE_B4;
                12'd1138: toneL = `NOTE_B4; 12'd1139: toneL = `NOTE_B4;

                12'd1140: toneL = `NOTE_B4; 12'd1141: toneL = `NOTE_B4;
                12'd1142: toneL = `NOTE_B4; 12'd1143: toneL = `NOTE_B4;
                12'd1144: toneL = `NOTE_B4; 12'd1145: toneL = `sil;
                12'd1146: toneL = `NOTE_AS5; 12'd1147: toneL = `NOTE_AS5;
                12'd1148: toneL = `NOTE_AS5; 12'd1149: toneL = `NOTE_AS5;
                12'd1150: toneL = `NOTE_AS5; 12'd1151: toneL = `NOTE_AS5;
//25th
                12'd1152: toneL = `NOTE_FS5; 12'd1153: toneL = `NOTE_FS5;
                12'd1154: toneL = `NOTE_FS5; 12'd1155: toneL = `NOTE_FS5;
                12'd1156: toneL = `NOTE_FS5; 12'd1157: toneL = `sil;
                12'd1158: toneL = `NOTE_A5; 12'd1159: toneL = `NOTE_A5;
                12'd1160: toneL = `NOTE_A5; 12'd1161: toneL = `NOTE_A5;
                12'd1162: toneL = `NOTE_A5; 12'd1163: toneL = `NOTE_A5;

                12'd1164: toneL = `NOTE_A5; 12'd1165: toneL = `NOTE_A5;
                12'd1166: toneL = `NOTE_A5; 12'd1167: toneL = `NOTE_A5;
                12'd1168: toneL = `NOTE_A5; 12'd1169: toneL = `sil;
                12'd1170: toneL = `NOTE_D5; 12'd1171: toneL = `NOTE_D5;
                12'd1172: toneL = `NOTE_D5; 12'd1173: toneL = `NOTE_D5;
                12'd1174: toneL = `NOTE_D5; 12'd1175: toneL = `sil;

                12'd1176: toneL = `NOTE_GS5; 12'd1177: toneL = `NOTE_GS5;
                12'd1178: toneL = `NOTE_GS5; 12'd1179: toneL = `NOTE_GS5;
                12'd1180: toneL = `NOTE_GS5; 12'd1181: toneL = `sil;
                12'd1182: toneL = `NOTE_GS5; 12'd1183: toneL = `NOTE_GS5;
                12'd1184: toneL = `NOTE_GS5; 12'd1185: toneL = `NOTE_GS5;
                12'd1186: toneL = `NOTE_GS5; 12'd1187: toneL = `sil;

                12'd1188: toneL = `NOTE_GS5; 12'd1189: toneL = `NOTE_GS5;
                12'd1190: toneL = `NOTE_GS5; 12'd1191: toneL = `NOTE_GS5;
                12'd1192: toneL = `NOTE_GS5; 12'd1193: toneL = `NOTE_GS5;
                12'd1194: toneL = `NOTE_GS5; 12'd1195: toneL = `NOTE_GS5;
                12'd1196: toneL = `NOTE_GS5; 12'd1197: toneL = `NOTE_GS5;
                12'd1198: toneL = `NOTE_GS5; 12'd1199: toneL = `sil;

                default : toneL = `sil;
            endcase
        end
        else begin
            toneL = `sil;
        end
    end
endmodule