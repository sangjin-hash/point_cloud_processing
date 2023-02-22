//
//  DetailsData.swift
//  Creadto
//
//  Created by 이상진 on 2023/01/31.
//

import Foundation

struct DetailsData {
    var code : String
    var eng_part : String
    var kor_part : String
    var value : String
}

/**
    둘레 : 부위 뒤에 아무것도 안붙힘
    길이 : Length
    너비 : Width
    위치 : Position
 */

extension DetailsData {
    static var data = [
        DetailsData(code: "X_Measure_1000", eng_part: "Height", kor_part: "키", value: "-"),
        DetailsData(code: "X_Measure_1001", eng_part: "Width of face(Front)", kor_part: "앞 얼굴 중심 너비", value: "-"),
        DetailsData(code: "X_Measure_1002", eng_part: "Neck", kor_part: "목 둘레", value: "-"),
        DetailsData(code: "X_Measure_1003", eng_part: "Front torso", kor_part: "앞 품", value: "-"),
        DetailsData(code: "X_Measure_1004", eng_part: "Chest", kor_part: "가슴 둘레", value: "-"),
        DetailsData(code: "X_Measure_1005", eng_part: "Waist", kor_part: "허리 둘레", value: "-"),
        DetailsData(code: "X_Measure_1006", eng_part: "Hip", kor_part: "엉덩이 둘레", value: "-"),
        DetailsData(code: "X_Measure_1007", eng_part: "Thigh", kor_part: "허벅지 둘레", value: "-"),
        DetailsData(code: "X_Measure_1008", eng_part: "Mid Thigh", kor_part: "허벅지 중간 둘레", value: "-"),
        DetailsData(code: "X_Measure_1009", eng_part: "Knee", kor_part: "무릎 둘레", value: "-"),
        DetailsData(code: "X_Measure_1010", eng_part: "Calf", kor_part: "종아리 둘레", value: "-"),
        DetailsData(code: "X_Measure_1011", eng_part: "Ankle", kor_part: "발목 둘레", value: "-"),
        DetailsData(code: "X_Measure_1101", eng_part: "Length of Face(Front)", kor_part: "앞 얼굴 중심 길이", value: "-"),
        DetailsData(code: "X_Measure_1102", eng_part: "Neck to Chest", kor_part: "유장", value: "-"),
        DetailsData(code: "X_Measure_1103", eng_part: "Length of torso(Front)", kor_part: "앞 길이", value: "-"),
        DetailsData(code: "X_Measure_1104", eng_part: "Length of torso(Center)", kor_part: "앞 중심 길이", value: "-"),
        DetailsData(code: "X_Measure_2001", eng_part: "Width of Armpit", kor_part: "겨드랑 너비", value: "-"),
        DetailsData(code: "X_Measure_2002", eng_part: "Armhole", kor_part: "암홀 둘레", value: "-"),
        DetailsData(code: "X_Measure_2101", eng_part: "Position of knee", kor_part: "무릎 위치", value: "-"),
        DetailsData(code: "X_Measure_2102", eng_part: "Height of knee", kor_part: "무릎 높이", value: "-"),
        DetailsData(code: "X_Measure_3001", eng_part: "Width of face(Side)", kor_part: "옆 얼굴 중심 너비", value: "-"),
        DetailsData(code: "X_Measure_3002", eng_part: "Width of shoulder", kor_part: "어깨 너비", value: "-"),
        DetailsData(code: "X_Measure_3003", eng_part: "Length of arm", kor_part: "팔 길이", value: "-"),
        DetailsData(code: "X_Measure_3004", eng_part: "Wrist", kor_part: "손목 둘레", value: "-"),
        DetailsData(code: "X_Measure_3005", eng_part: "Upper arm", kor_part: "윗팔 둘레", value: "-"),
        DetailsData(code: "X_Measure_3006", eng_part: "Elbow", kor_part: "팔꿈치 둘레", value: "-"),
        DetailsData(code: "X_Measure_3101", eng_part: "Length of upper arm", kor_part: "팔꿈치 길이", value: "-"),
        DetailsData(code: "X_Measure_3102", eng_part: "Length of torso(Vertical)", kor_part: "몸통 수직 길이", value: "-"),
        DetailsData(code: "X_Measure_3103", eng_part: "Length of hip(Vertical)", kor_part: "엉덩이 수직 길이", value: "-"),
        DetailsData(code: "X_Measure_3104", eng_part: "Length of hip", kor_part: "엉덩이 길이", value: "-"),
        DetailsData(code: "X_Measure_3105", eng_part: "Length of back", kor_part: "등 길이", value: "-"),
    ]
}
