//
//  AppDelegate.mm
//  CyberMatrix
//
//  Created by Six Pack Abs on 5/29/26.
//

#import "AppDelegate.h"


#include <algorithm>
#include <array>
#include <cstdint>
#include <cstdio>
#include <vector>
#include "M88.hpp"

#include <array>
#include <cstdint>
#include <cstdio>
#include <unordered_map>

@interface AppDelegate ()

@property (strong) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

static std::uint32_t NextRandomU32(std::uint32_t& pState) {
    pState = pState * 1664525U + 1013904223U;
    return pState;
}

static std::uint8_t NextRandomByte(std::uint32_t& pState) {
    return static_cast<std::uint8_t>(NextRandomU32(pState) >> 24U);
}

void TestDispatchPermuteRandomMix(std::uint32_t pSeed,
                                  std::uint64_t pLoops) {
    
    std::uint64_t aChangedCountHistogram[65] = {};
    std::uint64_t aTileChangedHistogram[64] = {};
    std::uint64_t aValueMovedDistanceHistogram[64] = {};
    std::uint64_t aBadChangedCount = 0;
    
    M88 aMat;
    
    for (std::uint64_t aLoop = 0; aLoop < pLoops; aLoop++) {
        
        std::array<std::uint8_t, 64> aBefore;
        std::array<std::uint8_t, 64> aAfter;
        
        aMat.Reset();
        
        for (std::size_t i = 0; i < 64U; i++) {
            aBefore[i] = aMat.mData[i];
        }
        
        std::uint8_t qAA = NextRandomByte(pSeed);
        std::uint8_t qAB = NextRandomByte(pSeed);
        std::uint8_t qBA = NextRandomByte(pSeed);
        std::uint8_t qBB = NextRandomByte(pSeed);
        std::uint8_t qCA = NextRandomByte(pSeed);
        std::uint8_t qCB = NextRandomByte(pSeed);
        std::uint8_t qDA = NextRandomByte(pSeed);
        std::uint8_t qDB = NextRandomByte(pSeed);
        
        std::uint8_t sA = NextRandomByte(pSeed);
        std::uint8_t sB = NextRandomByte(pSeed);
        std::uint8_t sC = NextRandomByte(pSeed);
        std::uint8_t sD = NextRandomByte(pSeed);
        std::uint8_t sE = NextRandomByte(pSeed);
        std::uint8_t sF = NextRandomByte(pSeed);
        std::uint8_t sG = NextRandomByte(pSeed);
        std::uint8_t sH = NextRandomByte(pSeed);
        
        std::uint8_t amount = static_cast<std::uint8_t>((NextRandomByte(pSeed) % 15U) + 1U);
        
        aMat.DispatchPermute(qAA, qAB, qBA, qBB, qCA, qCB, qDA, qDB,
                             sA, sB, sC, sD, sE, sF, sG, sH,
                             amount);
        
        for (std::size_t i = 0; i < 64U; i++) {
            aAfter[i] = aMat.mData[i];
        }
        
        std::uint32_t aChangedCount = 0;
        
        for (std::size_t i = 0; i < 64U; i++) {
            if (aBefore[i] != aAfter[i]) {
                aChangedCount++;
                aTileChangedHistogram[i]++;
            }
        }
        
        aChangedCountHistogram[aChangedCount]++;
        
        if (aChangedCount != 16U) {
            aBadChangedCount++;
            
            if (aBadChangedCount <= 10U) {
                std::printf("BAD changed count: loop=%llu changed=%u amount=%u\n",
                            static_cast<unsigned long long>(aLoop),
                            aChangedCount,
                            static_cast<unsigned int>(amount));
            }
        }
        
        //
        // Since Reset() makes value == original index,
        // after DispatchPermute, each value tells us where it came from.
        //
        // For every changed destination i:
        //
        //   aAfter[i] = old source index
        //
        // So abs(i - aAfter[i]) gives a rough linear distance.
        //
        
        for (std::size_t i = 0; i < 64U; i++) {
            if (aBefore[i] != aAfter[i]) {
                std::uint8_t aSourceIndex = aAfter[i];
                
                std::uint32_t aDistance;
                
                if (i >= static_cast<std::size_t>(aSourceIndex)) {
                    aDistance = static_cast<std::uint32_t>(i - aSourceIndex);
                } else {
                    aDistance = static_cast<std::uint32_t>(aSourceIndex - i);
                }
                
                if (aDistance < 64U) {
                    aValueMovedDistanceHistogram[aDistance]++;
                }
            }
        }
    }
    
    std::printf("loops: %llu\n", static_cast<unsigned long long>(pLoops));
    std::printf("bad changed-count loops: %llu\n",
                static_cast<unsigned long long>(aBadChangedCount));
    
    std::printf("\nchanged count histogram:\n");
    for (int i = 0; i <= 64; i++) {
        if (aChangedCountHistogram[i] > 0) {
            std::printf("%2d changed: %llu\n",
                        i,
                        static_cast<unsigned long long>(aChangedCountHistogram[i]));
        }
    }
    
    std::printf("\ntile changed histogram:\n");
    for (int y = 0; y < 8; y++) {
        for (int x = 0; x < 8; x++) {
            int i = y * 8 + x;
            std::printf("%8llu ",
                        static_cast<unsigned long long>(aTileChangedHistogram[i]));
        }
        std::printf("\n");
    }
    
    std::printf("\nlinear moved-distance histogram:\n");
    for (int i = 0; i < 64; i++) {
        if (aValueMovedDistanceHistogram[i] > 0) {
            std::printf("distance %2d: %llu\n",
                        i,
                        static_cast<unsigned long long>(aValueMovedDistanceHistogram[i]));
        }
    }
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    
    TestDispatchPermuteRandomMix(0x12345678U, 100000ULL);
    
    // TestPermuteSwapDistribution2Bytes();

    
    
    //
    //
    
    //TestFileExporter4x4And8x8::Export("tests/_Falcon", RecipeFactory4x4::FalconD(), RecipeFactory8x8::FalconD());
    
    
    /*
    RecipeExporterQuadAndFull::Export({
        { RecipeFactory4x4::WizardA(), RecipeFactory8x8::WizardA() },
        { RecipeFactory4x4::WizardB(), RecipeFactory8x8::WizardB() },
        { RecipeFactory4x4::WizardC(), RecipeFactory8x8::WizardC() },
        { RecipeFactory4x4::WizardD(), RecipeFactory8x8::WizardD() },
    });
    */
    
    //UniqueQuarterTool::PrintCompareCandidates();
    
    //UniqueQuarterTool::PrintCompareExistingOpsToEachOther();
    
    //return;
    
    //return;
    
    //UniqueQuarterTool::PrintCompareCandidates();
    
    //return;
    
    //PrintRecipeTool::PrintRecipeFactories(aEntries);
    
    //return;
    
    /*
    RecipeExporterQuadAndFull::Export({
        { RecipeFactory4x4::GlendaleA(),  RecipeFactory8x8::GlendaleA() },
        { RecipeFactory4x4::GlendaleB(),  RecipeFactory8x8::GlendaleB() },
        { RecipeFactory4x4::GlendaleC(),  RecipeFactory8x8::GlendaleC() },
        { RecipeFactory4x4::GlendaleD(),  RecipeFactory8x8::GlendaleD() },

        { RecipeFactory4x4::BurbankA(),   RecipeFactory8x8::BurbankA() },
        { RecipeFactory4x4::BurbankB(),   RecipeFactory8x8::BurbankB() },
        { RecipeFactory4x4::BurbankC(),   RecipeFactory8x8::BurbankC() },
        { RecipeFactory4x4::BurbankD(),   RecipeFactory8x8::BurbankD() },

        { RecipeFactory4x4::InglewoodA(), RecipeFactory8x8::InglewoodA() },
        { RecipeFactory4x4::InglewoodB(), RecipeFactory8x8::InglewoodB() },
        { RecipeFactory4x4::InglewoodC(), RecipeFactory8x8::InglewoodC() },
        { RecipeFactory4x4::InglewoodD(), RecipeFactory8x8::InglewoodD() },

        { RecipeFactory4x4::PasadenaA(),  RecipeFactory8x8::PasadenaA() },
        { RecipeFactory4x4::PasadenaB(),  RecipeFactory8x8::PasadenaB() },
        { RecipeFactory4x4::PasadenaC(),  RecipeFactory8x8::PasadenaC() },
        { RecipeFactory4x4::PasadenaD(),  RecipeFactory8x8::PasadenaD() },

        { RecipeFactory4x4::TorranceA(),  RecipeFactory8x8::TorranceA() },
        { RecipeFactory4x4::TorranceB(),  RecipeFactory8x8::TorranceB() },
        { RecipeFactory4x4::TorranceC(),  RecipeFactory8x8::TorranceC() },
        { RecipeFactory4x4::TorranceD(),  RecipeFactory8x8::TorranceD() },

        { RecipeFactory4x4::HawthorneA(), RecipeFactory8x8::HawthorneA() },
        { RecipeFactory4x4::HawthorneB(), RecipeFactory8x8::HawthorneB() },
        { RecipeFactory4x4::HawthorneC(), RecipeFactory8x8::HawthorneC() },
        { RecipeFactory4x4::HawthorneD(), RecipeFactory8x8::HawthorneD() }
    });
    
    return;
    
    */
    
    
    
    /*
    RecipeExporterQuadAndFull::Export({
        { RecipeFactory4x4::HeronA(),  RecipeFactory8x8::HeronA() },
        { RecipeFactory4x4::HeronB(),  RecipeFactory8x8::HeronB() },
        { RecipeFactory4x4::HeronC(),  RecipeFactory8x8::HeronC() },
        { RecipeFactory4x4::HeronD(),  RecipeFactory8x8::HeronD() },

        { RecipeFactory4x4::FalconA(), RecipeFactory8x8::FalconA() },
        { RecipeFactory4x4::FalconB(), RecipeFactory8x8::FalconB() },
        { RecipeFactory4x4::FalconC(), RecipeFactory8x8::FalconC() },
        { RecipeFactory4x4::FalconD(), RecipeFactory8x8::FalconD() }
    });
    */
    
    //
    //
    //
    
    
    //
    
    
    //TestFileExporter4x4And8x8::Export(RecipeFactory4x4::GooseD(), RecipeFactory8x8::GooseD());
    //return;
    
    
    //RecipeExporter4x4::Export(RecipeFactory4x4::SwanA());
    //RecipeExporter8x8::Export(RecipeFactory8x8::SwanA());
    
    //UniqueQuarterTool::PrintCompareExistingOpsToEachOther();
    
    /*
    RecipeExporterQuadAndFull::Export({
        { RecipeFactory4x4::SwanA(),  RecipeFactory8x8::SwanA() },
        { RecipeFactory4x4::SwanB(),  RecipeFactory8x8::SwanB() },
        { RecipeFactory4x4::SwanC(),  RecipeFactory8x8::SwanC() },
        { RecipeFactory4x4::SwanD(),  RecipeFactory8x8::SwanD() },

        { RecipeFactory4x4::GooseA(), RecipeFactory8x8::GooseA() },
        { RecipeFactory4x4::GooseB(), RecipeFactory8x8::GooseB() },
        { RecipeFactory4x4::GooseC(), RecipeFactory8x8::GooseC() },
        { RecipeFactory4x4::GooseD(), RecipeFactory8x8::GooseD() }
    });
    */
    
    
    
    //RecipeExporter4x4::Export(RecipeFactory4x4::PeridotD());
    //TestExporter4x4::Export(RecipeFactory4x4::CrystalA());
    
    
    //DebugCandidateAIdentity();
    //printf("?");
    
    //RecipeExporter8x8::Export(RecipeFactory8x8::PeridotD());
    //TestExporter8x8::Export(RecipeFactory8x8::JewelA());
    
    
    //PrintRecipeTool::PrintRecipeFactories(aEntries);
    
    
    //UniqueQuarterTool::PrintCompareCandidates();
    
    
    //return;
    


    
    //RecipeExporter2x2::Export(RecipeFactory2x2::SwapD());
    //TestExporter2x2::Export(RecipeFactory2x2::SwapD());
    
    //RecipeExporter4x4::Export(RecipeFactory4x4::FoldD());
    //TestExporter4x4::Export(RecipeFactory4x4::PeridotA());
    
    //RecipeExporter8x8::Export(RecipeFactory8x8::ShearD());
    //TestExporter8x8::Export(RecipeFactory8x8::PeridotB());
    
    /*
    TestFileExporter4x4And8x8::Export(RecipeFactory4x4::JewelD(),
                                      RecipeFactory8x8::JewelD());
    */
    
    //TestUniqueMatrix();
    
    
    /*
    const std::string aName = "NameA";
    void (Slice::*aFunctionA)() = &Slice::_Identity;
    void (Slice::*aFunctionB)() = &Slice::_RotA;

    M88 aMatrix;

    aMatrix.Reset();
    Slice aSliceA = aMatrix.GetQuadA();
    aSliceA.PrepareSlots();
    (aSliceA.*aFunctionA)();
    (aSliceA.*aFunctionB)();
    aSliceA.RealizeSlots();
    aMatrix.RecordStart();
    aMatrix.Paste(aSliceA);
    aMatrix.RecordStop();
    aSliceA.PrintRecipeFactory4x4(aName);

    aMatrix.Reset();
    Slice aSliceB = aMatrix.GetFull();
    aSliceB.PrepareSlots();
    (aSliceB.*aFunctionA)();
    (aSliceB.*aFunctionB)();
    aSliceB.RealizeSlots();
    aMatrix.RecordStart();
    aMatrix.Paste(aSliceB);
    aMatrix.RecordStop();
    aSliceB.PrintRecipeFactory8x8(aName);
    */
    
    
    
    /*
    M88 aMatrix;
    aMatrix.Reset();
    Slice aSlice = aMatrix.GetMiniA();
    //Slice aSlice = aMatrix.GetQuadA();
    //Slice aSlice = aMatrix.GetFull();
    
    
    aSlice.PrepareSlots();
    
    aSlice._FlipD();
    
    aSlice.RealizeSlots();
    aMatrix.RecordStart();
    aMatrix.Paste(aSlice);
    aMatrix.RecordStop();
    aSlice.PrintRecipeFactory2x2("FlipD");
    //aSlice.PrintRecipeFactory4x4("FlipD");
    //aSlice.PrintRecipeFactory8x8("FlipD");
    */
    
    
    
    
    //RecipeExporter2x2::Export(RecipeFactory2x2::RotA());
    //TestExporter2x2::Export(RecipeFactory2x2::RotA());
    
    //RecipeExporter4x4::Export(RecipeFactory4x4::RotA());
    //TestExporter4x4::Export(RecipeFactory4x4::RotA());
    
    //RecipeExporter8x8::Export(RecipeFactory8x8::RotA());
    //TestExporter8x8::Export(RecipeFactory8x8::RotA());
    
    
    /*
    M88 aMatrix;
    aMatrix.Reset();

    Slice aSlice = aMatrix.GetFull();
    
    aSlice.PrepareSlots();

    aSlice._PinB();
    
    aSlice.RealizeSlots();


    aMatrix.RecordStart();
    aMatrix.Paste(aSlice);
    aMatrix.RecordStop();

    aSlice.PrintRecipeFactory4x4("PinB");
    */
    
    
    //
    //
    
    
    //RecipeExporter4x4::Export(RecipeFactory4x4::RotA());
    
    //RecipeExporter4x4::Export(RecipeFactory4x4::CastleA());
    
    
    //MakeEachMiniCPP("SnakeA", Op::kSnakeA);
    //MakeEachMiniCPP("SnakeB", Op::kSnakeB);
    //MakeEachMiniCPP("SnakeC", Op::kSnakeC);
    //MakeEachMiniCPP("SnakeD", Op::kSnakeD);
    
    //MakeEachMini("FlipD", Op::kFlipD);
    
    //MakeEachMiniCPP("RotD", Op::kRotC);
    
    //Slice aSlice = Slice(0, 0, 2);
    //aSlice.PrintBlockMapFunction("Glob");
    //aSlice.PrintVerifyExpected("VerifyQuad", "QuadPinAExpected");
    
    /*
    
    M88 aMatrix;
    aMatrix.Reset();

    Slice aSlice = aMatrix.GetQuadA();
    Quint aQuintCorners = aSlice.GetQuintRight(0, 0);
    Quint aQuintCentersRight = aSlice.GetQuintRight(2, 1);

    aSlice.PrepareSlots();

    aSlice._Weave(aQuintCorners, aQuintCentersRight);


    Quint aQuintEdgeA = aSlice.GetQuintRight(1, 0);
    Quint aQuintEdgeB = aSlice.GetQuintRight(2, 0);

    aQuintEdgeA.Print();

    aSlice._RotB(aQuintEdgeA);
    aSlice._RotB(aQuintEdgeB);

    //aSlice._Weave(aQuintEdgeA, aQuintEdgeB);
    aSlice.RealizeSlots();


    aMatrix.RecordStart();
    aMatrix.Paste(aSlice);
    aMatrix.RecordStop();

    aSlice.PrintRecipeFactory4x4("CastleA");

    printf("all done...\n");
    printf("all done...\n");
    
    */
    
    /*
     std::vector<std::string> aNameChunks;
    aNameChunks.push_back(pOpName);

    aFull.PrintHPP(aNameChunks);

    if (aMatrix.HasChange()) {
        aMatrix.RecordPrintFunction(pOpName, "", 0);
    }
    */
    
    /*
    if (aFull.Capable(pOp)) {
        aFull.Execute(pOp);

        aMatrix.RecordStart();
        aMatrix.Paste(aFull);
        aMatrix.RecordStop();

        std::vector<std::string> aNameChunks;
        aNameChunks.push_back(pOpName);

        aFull.PrintHPP(aNameChunks);

        if (aMatrix.HasChange()) {
            aMatrix.RecordPrintFunction(pOpName, "", 0);
        }
    } else {
        std::printf("%s not possible for full matrix\n", pOpName);
    }
    */
    
    
    //MakeFull("FlipA", Op::kFlipA);
    //MakeFull("FlipB", Op::kFlipB);
    //MakeFull("FlipC", Op::kFlipC);
    //MakeFull("FlipD", Op::kFlipD);
    
    
    /*
    MakeFull("RotA", Op::kRotA);
    MakeFull("RotB", Op::kRotB);
    MakeFull("RotC", Op::kRotC);

    MakeFull("BlockRotA", Op::kBlockRotA);
    MakeFull("BlockRotB", Op::kBlockRotB);
    MakeFull("BlockRotC", Op::kBlockRotC);

    MakeFull("PylonRotA", Op::kPylonRotA);
    MakeFull("PylonRotB", Op::kPylonRotB);
    MakeFull("PylonRotC", Op::kPylonRotC);
    */
    
    // TryRotateRightQuadA();
    
    /*
    M88 aMatrix;
    aMatrix.Reset();

    Slice aQuadA = aMatrix.GetQuadA();

    if (aQuadA.Capable(Op::kRotateRight)) {
        aQuadA.Execute(Op::kRotateRight);
        
        aMatrix.RecordStart();
        aMatrix.Paste(aQuadA);
        aMatrix.RecordStop();
        
        if (aMatrix.HasChange()) {
            
            aMatrix.RecordPrintFunction("RotateRight", "Quad", 0);
        } else {
            printf("kRotateRight identity for 4 x 4");
        }
        
        
    } else {
        printf("kRotateRight not possible for 4 x 4");
    }
    
    */
    
    
    return;
    
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


- (BOOL)applicationSupportsSecureRestorableState:(NSApplication *)app {
    return YES;
}


@end
