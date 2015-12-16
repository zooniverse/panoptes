require 'spec_helper'

RSpec.describe Warehouse::SurveyTaskFormatter do
  let(:definition) do
    {
      "type"=>"survey",
      "images"=>[],
      "choices"=>
        {"FR"=> {"image"=>[], "label"=>"T1.choices.FR.label", "images"=>["fire-1.jpg"], "confusions"=>{}, "description"=> "This is what fire looks like. You might see it with species or on its own.", "noQuestions"=>true, "characteristics"=> {"LK"=>[], "TL"=>[], "BLD"=>[], "CLR"=>[], "HRNS"=>[], "PTTRN"=>[]}, "confusionsOrder"=>[]},
        "HN"=> {"image"=>[], "label"=>"T1.choices.HN.label", "images"=>["hyena-1.jpg", "hyena-2.jpg", "hyena-3.jpg"], "confusions"=> {"WLDDG"=> "A wild dog is more slender than a hyena with patchy black, orange, and white fur and a flat back."}, "description"=> "Medium-sized, stocky, doglike animal with a thick neck and a sloped back, golden tan-gray fur with dark spots, and small, round ears.", "noQuestions"=>false, "characteristics"=> {"LK"=>["CTDG"], "TL"=>["BSH"], "BLD"=>["STCK", "LNK"], "CLR"=>["TNLLW", "BRWN", "BLCK"], "HRNS"=>[], "PTTRN"=>["SPTS"]}, "confusionsOrder"=>["WLDDG"]},
        "HR"=> {"image"=>[], "label"=>"T1.choices.HR.label", "images"=>["hare-1.jpg", "hare-2.jpg", "hare-3.jpg"], "confusions"=>{}, "description"=> "Large rabbitlike animal with very long ears. There are two hare species in Gorongosa. The savanna hare has gray fur with a lighter brown underbelly, while the scrub hare is darker gray and has a white underbelly.", "noQuestions"=>false, "characteristics"=> {"LK"=>["THR"], "TL"=>["BSH", "SHRT"], "BLD"=>["SMLL", "LWSLNG"], "CLR"=>["TNLLW", "BRWN", "WHT", "GR"], "HRNS"=>[], "PTTRN"=>["SLD"]}, "confusionsOrder"=>[]}},
      "questions"=>
        {"HWMN"=>
        {"label"=>"T1.questions.HWMN.label",
        "answers"=> {"1"=>{"label"=>"T1.questions.HWMN.answers.1.label"}, "2"=>{"label"=>"T1.questions.HWMN.answers.2.label"}, "1150"=>{"label"=>"T1.questions.HWMN.answers.1150.label"}},
        "multiple"=>false,
        "required"=>true,
        "answersOrder"=>
          ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "1150", "51"]},
      "DSNHRNS"=> {"label"=>"T1.questions.DSNHRNS.label", "answers"=> {"N"=>{"label"=>"T1.questions.DSNHRNS.answers.N.label"}, "S"=>{"label"=>"T1.questions.DSNHRNS.answers.S.label"}}, "multiple"=>false, "required"=>false, "answersOrder"=>["S", "N"]},
      "WHTBHVRSDS"=> {"label"=>"T1.questions.WHTBHVRSDS.label", "answers"=> {"TNG"=>{"label"=>"T1.questions.WHTBHVRSDS.answers.TNG.label"}, "MVNG"=>{"label"=>"T1.questions.WHTBHVRSDS.answers.MVNG.label"}, "RSTNG"=>{"label"=>"T1.questions.WHTBHVRSDS.answers.RSTNG.label"}, "STNDNG"=>{"label"=>"T1.questions.WHTBHVRSDS.answers.STNDNG.label"}, "NTRCTNG"=>{"label"=>"T1.questions.WHTBHVRSDS.answers.NTRCTNG.label"}}, "multiple"=>true, "required"=>true, "answersOrder"=>["RSTNG", "STNDNG", "MVNG", "TNG", "NTRCTNG"]},
      "RTHRNNGPRSNT"=> {"label"=>"T1.questions.RTHRNNGPRSNT.label", "answers"=> {"N"=>{"label"=>"T1.questions.RTHRNNGPRSNT.answers.N.label"}, "S"=>{"label"=>"T1.questions.RTHRNNGPRSNT.answers.S.label"}}, "multiple"=>false, "required"=>false, "answersOrder"=>["S", "N"]}},
      "choicesOrder"=> ["RDVRK", "BBN", "BRDTHR", "BFFL", "BSHBCK", "BSHPG", "CRCL", "CVT", "CRN", "DKR", "LND", "LPHNT", "GNT", "GRNDHRNBLL", "HR", "HRTBST", "HPPPTMS", "HNBDGR", "HN", "MPL", "JCKL", "KD", "LPRD", "LNCB", "LNFML", "LNML", "MNGS", "NL", "RB", "TTR", "PNGLN", "PRCPN", "RPTRTHR", "RDBCK", "RPTL", "RDNT", "SBLNTLP", "SMNGMNK", "SCRTRBRD", "SRVL", "VRVTMNK", "VLTR", "WRTHG", "WTRBCK", "WSL", "WLDDG", "WLDCT", "WLDBST", "ZBR", "HMN", "FR", "NTHNGHR"],
      "questionsOrder"=>["HWMN", "WHTBHVRSDS", "RTHRNNGPRSNT", "DSNHRNS"],
      "characteristics"=> {"LK"=> {"label"=>"T1.characteristics.LK.label", "values"=> {"BRD"=> {"image"=>"bird-icon.svg", "label"=>"T1.characteristics.LK.values.BRD.label"}, "THR"=> {"image"=>"nothing-icon.svg", "label"=>"T1.characteristics.LK.values.THR.label"}, "WSL"=> {"image"=>"weasel-icon.svg", "label"=>"T1.characteristics.LK.values.WSL.label"}, "CTDG"=> {"image"=>"cat-dog-icon.svg", "label"=>"T1.characteristics.LK.values.CTDG.label"}, "PRMT"=> {"image"=>"primate-icon.svg", "label"=>"T1.characteristics.LK.values.PRMT.label"}, "CWHRS"=> {"image"=>"cow-horse-icon.svg", "label"=>"T1.characteristics.LK.values.CWHRS.label"}, "NTLPDR"=> {"image"=>"ante-deer-icon.svg", "label"=>"T1.characteristics.LK.values.NTLPDR.label"}}, "valuesOrder"=>["CTDG", "CWHRS", "NTLPDR", "PRMT", "WSL", "BRD", "THR"]},
      "TL"=> {"label"=>"T1.characteristics.TL.label", "values"=> {"BSH"=> {"image"=>"bushy-icon.svg", "label"=>"T1.characteristics.TL.values.BSH.label"}, "LNG"=> {"image"=>"long-icon.svg", "label"=>"T1.characteristics.TL.values.LNG.label"}, "SHRT"=> {"image"=>"short-icon.svg", "label"=>"T1.characteristics.TL.values.SHRT.label"}, "SMTH"=> {"image"=>"smooth-icon.svg", "label"=>"T1.characteristics.TL.values.SMTH.label"}, "TFTD"=> {"image"=>"tafted-icon.svg", "label"=>"T1.characteristics.TL.values.TFTD.label"}}, "valuesOrder"=>["SMTH", "BSH", "TFTD", "LNG", "SHRT"]},
      "BLD"=> {"label"=>"T1.characteristics.BLD.label", "values"=> {"LNK"=> {"image"=>"lanky-icon.svg", "label"=>"T1.characteristics.BLD.values.LNK.label"}, "LRG"=> {"image"=>"large-icon.svg", "label"=>"T1.characteristics.BLD.values.LRG.label"}, "SMLL"=> {"image"=>"small-icon.svg", "label"=>"T1.characteristics.BLD.values.SMLL.label"}, "STCK"=> {"image"=>"stocky-icon.svg", "label"=>"T1.characteristics.BLD.values.STCK.label"}, "LWSLNG"=> {"image"=>"lowslung-icon.svg", "label"=>"T1.characteristics.BLD.values.LWSLNG.label"}}, "valuesOrder"=>["STCK", "LNK", "LRG", "SMLL", "LWSLNG"]},
      "CLR"=> {"label"=>"T1.characteristics.CLR.label", "values"=> {"GR"=> {"image"=>"gray.svg", "label"=>"T1.characteristics.CLR.values.GR.label"}, "RD"=> {"image"=>"red.svg", "label"=>"T1.characteristics.CLR.values.RD.label"}, "WHT"=> {"image"=>"white.svg", "label"=>"T1.characteristics.CLR.values.WHT.label"}, "BLCK"=> {"image"=>"black.svg", "label"=>"T1.characteristics.CLR.values.BLCK.label"}, "BRWN"=> {"image"=>"brown.svg", "label"=>"T1.characteristics.CLR.values.BRWN.label"}, "TNLLW"=> {"image"=>"tan-yellow.svg", "label"=>"T1.characteristics.CLR.values.TNLLW.label"}}, "valuesOrder"=>["TNLLW", "RD", "BRWN", "WHT", "GR", "BLCK"]},
      "HRNS"=> {"label"=>"T1.characteristics.HRNS.label", "values"=> {"CRVD"=> {"image"=>"curved-icon.svg", "label"=>"T1.characteristics.HRNS.values.CRVD.label"}, "SHPD"=> {"image"=>"u-shaped-icon.svg", "label"=>"T1.characteristics.HRNS.values.SHPD.label"}, "SPRL"=> {"image"=>"spiral-horns-icon.svg", "label"=>"T1.characteristics.HRNS.values.SPRL.label"}, "STRGHT"=> {"image"=>"straight-icon.svg", "label"=>"T1.characteristics.HRNS.values.STRGHT.label"}}, "valuesOrder"=>["STRGHT", "CRVD", "SPRL", "SHPD"]},
      "PTTRN"=> {"label"=>"T1.characteristics.PTTRN.label",
        "values"=> {"SLD"=> {"image"=>"solid-icon.svg", "label"=>"T1.characteristics.PTTRN.values.SLD.label"}, "BNDS"=> {"image"=>"banding-icon.svg", "label"=>"T1.characteristics.PTTRN.values.BNDS.label"}, "SPTS"=> {"image"=>"spots-icon.svg", "label"=>"T1.characteristics.PTTRN.values.SPTS.label"}, "STRPS"=> {"image"=>"stripes-icon.svg", "label"=>"T1.characteristics.PTTRN.values.STRPS.label"}}, "valuesOrder"=>["SLD", "STRPS", "BNDS", "SPTS"]}},
      "characteristicsOrder"=>["LK", "PTTRN", "CLR", "HRNS", "TL", "BLD"]}
  end

  let(:translations) do
    {
      "T1.choices.RDVRK.label"=>"Aardvark",
      "T1.choices.BBN.label"=>"Baboon",
      "T1.choices.BRDTHR.label"=>"Bird (other)",
      "T1.choices.BFFL.label"=>"Buffalo",
      "T1.choices.BSHBCK.label"=>"Bushbuck",
      "T1.choices.BSHPG.label"=>"Bushpig",
      "T1.choices.CRCL.label"=>"Caracal",
      "T1.choices.CVT.label"=>"Civet",
      "T1.choices.CRN.label"=>"Crane",
      "T1.choices.DKR.label"=>"Duiker",
      "T1.choices.LND.label"=>"Eland",
      "T1.choices.LPHNT.label"=>"Elephant",
      "T1.choices.GNT.label"=>"Genet",
      "T1.choices.GRNDHRNBLL.label"=>"Ground Hornbill",
      "T1.choices.HR.label"=>"Hare",
      "T1.choices.HRTBST.label"=>"Hartebeest",
      "T1.choices.HPPPTMS.label"=>"Hippopotamus",
      "T1.choices.HNBDGR.label"=>"Honey Badger",
      "T1.choices.HN.label"=>"Hyena",
      "T1.choices.MPL.label"=>"Impala",
      "T1.choices.JCKL.label"=>"Jackal",
      "T1.choices.KD.label"=>"Kudu",
      "T1.choices.LPRD.label"=>"Leopard",
      "T1.choices.LNCB.label"=>"Lion (cub)",
      "T1.choices.LNFML.label"=>"Lion (female)",
      "T1.choices.LNML.label"=>"Lion (male)",
      "T1.choices.MNGS.label"=>"Mongoose",
      "T1.choices.NL.label"=>"Nyala",
      "T1.choices.RB.label"=>"Oribi",
      "T1.choices.TTR.label"=>"Otter",
      "T1.choices.PNGLN.label"=>"Pangolin",
      "T1.choices.PRCPN.label"=>"Porcupine",
      "T1.choices.RPTRTHR.label"=>"Raptor (other)",
      "T1.choices.RDBCK.label"=>"Reedbuck",
      "T1.choices.RPTL.label"=>"Reptile",
      "T1.choices.RDNT.label"=>"Rodent",
      "T1.choices.SBLNTLP.label"=>"Sable Antelope",
      "T1.choices.SMNGMNK.label"=>"Samango Monkey",
      "T1.choices.SCRTRBRD.label"=>"Secretary bird",
      "T1.choices.SRVL.label"=>"Serval",
      "T1.choices.VRVTMNK.label"=>"Vervet Monkey",
      "T1.choices.VLTR.label"=>"Vulture",
      "T1.choices.WRTHG.label"=>"Warthog",
      "T1.choices.WTRBCK.label"=>"Waterbuck",
      "T1.choices.WSL.label"=>"Weasel",
      "T1.choices.WLDDG.label"=>"Wild Dog",
      "T1.choices.WLDCT.label"=>"Wildcat",
      "T1.choices.WLDBST.label"=>"Wildebeest",
      "T1.choices.ZBR.label"=>"Zebra",
      "T1.choices.HMN.label"=>"Human",
      "T1.choices.FR.label"=>"Fire",
      "T1.choices.NTHNGHR.label"=>"Nothing here",
      "T1.questions.HWMN.label"=>"How many?",
      "T1.questions.HWMN.answers.1.label"=>"1",
      "T1.questions.HWMN.answers.2.label"=>"2",
      "T1.questions.HWMN.answers.3.label"=>"3",
      "T1.questions.HWMN.answers.4.label"=>"4",
      "T1.questions.HWMN.answers.5.label"=>"5",
      "T1.questions.HWMN.answers.6.label"=>"6",
      "T1.questions.HWMN.answers.7.label"=>"7",
      "T1.questions.HWMN.answers.8.label"=>"8",
      "T1.questions.HWMN.answers.9.label"=>"9",
      "T1.questions.HWMN.answers.10.label"=>"10",
      "T1.questions.HWMN.answers.51.label"=>"51+",
      "T1.questions.HWMN.answers.1150.label"=>"11-50",
      "T1.questions.WHTBHVRSDS.label"=>"What behaviors do you see?",
      "T1.questions.WHTBHVRSDS.answers.RSTNG.label"=>"Resting",
      "T1.questions.WHTBHVRSDS.answers.STNDNG.label"=>"Standing",
      "T1.questions.WHTBHVRSDS.answers.MVNG.label"=>"Moving",
      "T1.questions.WHTBHVRSDS.answers.TNG.label"=>"Eating",
      "T1.questions.WHTBHVRSDS.answers.NTRCTNG.label"=>"Interacting",
      "T1.questions.RTHRNNGPRSNT.label"=>"Are there any young present?",
      "T1.questions.RTHRNNGPRSNT.answers.S.label"=>"Yes",
      "T1.questions.RTHRNNGPRSNT.answers.N.label"=>"No",
      "T1.questions.DSNHRNS.label"=>"Do you see any horns?",
      "T1.questions.DSNHRNS.answers.S.label"=>"Yes",
      "T1.questions.DSNHRNS.answers.N.label"=>"No",
      "T1.characteristics.LK.label"=>"Like",
      "T1.characteristics.LK.values.CTDG.label"=>"cat/dog",
      "T1.characteristics.LK.values.CWHRS.label"=>"cow/horse",
      "T1.characteristics.LK.values.NTLPDR.label"=>"antelope/deer",
      "T1.characteristics.LK.values.PRMT.label"=>"primate",
      "T1.characteristics.LK.values.WSL.label"=>"weasel",
      "T1.characteristics.LK.values.BRD.label"=>"bird",
      "T1.characteristics.LK.values.THR.label"=>"other",
      "T1.characteristics.PTTRN.label"=>"Pattern",
      "T1.characteristics.PTTRN.values.SLD.label"=>"solid",
      "T1.characteristics.PTTRN.values.STRPS.label"=>"stripes",
      "T1.characteristics.PTTRN.values.BNDS.label"=>"bands",
      "T1.characteristics.PTTRN.values.SPTS.label"=>"spots",
      "T1.characteristics.CLR.label"=>"color",
      "T1.characteristics.CLR.values.TNLLW.label"=>"tan/yellow",
      "T1.characteristics.CLR.values.RD.label"=>"red",
      "T1.characteristics.CLR.values.BRWN.label"=>"brown",
      "T1.characteristics.CLR.values.WHT.label"=>"white",
      "T1.characteristics.CLR.values.GR.label"=>"gray",
      "T1.characteristics.CLR.values.BLCK.label"=>"black",
      "T1.characteristics.HRNS.label"=>"Horns",
      "T1.characteristics.HRNS.values.STRGHT.label"=>"straight",
      "T1.characteristics.HRNS.values.CRVD.label"=>"curved",
      "T1.characteristics.HRNS.values.SPRL.label"=>"spiral",
      "T1.characteristics.HRNS.values.SHPD.label"=>"u-shaped",
      "T1.characteristics.TL.label"=>"Tail",
      "T1.characteristics.TL.values.SMTH.label"=>"smooth",
      "T1.characteristics.TL.values.BSH.label"=>"bushy",
      "T1.characteristics.TL.values.TFTD.label"=>"tufted",
      "T1.characteristics.TL.values.LNG.label"=>"long",
      "T1.characteristics.TL.values.SHRT.label"=>"short",
      "T1.characteristics.BLD.label"=>"Build",
      "T1.characteristics.BLD.values.STCK.label"=>"stocky",
      "T1.characteristics.BLD.values.LNK.label"=>"lanky",
      "T1.characteristics.BLD.values.LRG.label"=>"large",
      "T1.characteristics.BLD.values.SMLL.label"=>"small",
      "T1.characteristics.BLD.values.LWSLNG.label"=>"low-slung"}
  end

  let(:formatted) do
    described_class.new(task_definition: definition, translations: translations).format(annotation)
  end

  context 'for a simple annotation' do
    let(:annotation) do
      {
        "task"=>"T1",
        "value"=>{
          "choice"=>"MPL",
          "answers"=>{"HWMN"=>"1", "DSNHRNS"=>"N", "WHTBHVRSDS"=>["MVNG"], "RTHRNNGPRSNT"=>"N"},
          "filters"=>{"LK"=>"NTLPDR", "TL"=>"SHRT", "CLR"=>"BRWN"}
        }
      }
    end

    it 'returns basic data about the annotation', :aggregate_failures do
      expect(formatted[:task]).to eq(annotation["task"])
      expect(formatted[:task_label]).to eq(nil)
      expect(formatted[:task_type]).to eq("survey")
      expect(formatted[:choice]).to eq("MPL")
      expect(formatted[:answers]).to eq(annotation["value"]["answers"].to_json)
      expect(formatted[:filters]).to eq(annotation["value"]["filters"].to_json)
    end
  end
end
