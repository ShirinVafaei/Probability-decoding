% % Preperations

clear all;

root_path = '/home/svafaee/Codes/probabilityDecoding/predictingProbabilityFromBrainActivity/fMRI_analysis';
data_path = '/home/svafaee/Codes/fMRI/EmotionHorikawaCowenKeltner/11988351/data/fmri';

addpath(genpath('/home/svafaee/Codes/probabilityDecoding/Library/BrainDecoderToolbox2-master'));
addpath(genpath('/home/svafaee/Codes/probabilityDecoding/Library/cdtLRtool_v2_20181112'));

tag4version='LR1';


n_Subjects = 5;

lambda=[0.0005 0.001 0.005 0.01 0.05 0.1 0.5 1.0];
lambda2=[1];

[sample_h5_data, metadata] = load_data(fullfile(data_path, 'Subject1/preprocessed', 'fmri_Subject1_Session1.h5'));


ROIname{1}='V1';
ROIname{2}='V2';
ROIname{3}='V3';
ROIname{4}='V4';
ROIname{5}='LO';
ROIname{6}='FFC';
ROIname{7}='PHA';
ROIname{8}='HVC';
ROIname{9}='LVC';
ROIname{10}='VC';
ROIkeys=[];

for index_ROIname=1:7
    temporal_str=[];
    for index_key=1:length(metadata.key)
        if ~isempty(strfind(metadata.key{index_key},ROIname{index_ROIname}))
            if isempty(temporal_str)
                temporal_str=[metadata.key{index_key} ' = 1 '];
            else
                temporal_str=[temporal_str '| ' metadata.key{index_key} ' = 1 '];
            end
        end
    end
    ROIkeys{index_ROIname}=temporal_str;
end

ROIkeys{8}=[ROIkeys{5} ' | ' ROIkeys{6} ' | ' ROIkeys{7}];
ROIkeys{9}=[ROIkeys{1} ' | ' ROIkeys{2} ' | ' ROIkeys{3}];
ROIkeys{10}=[ROIkeys{1} ' | ' ROIkeys{2} ' | ' ROIkeys{3} ' | ' ROIkeys{4} ' | ' ROIkeys{8}];


ROI_keys{1} = {'hcp180_L_V1', 'hcp180_R_V1', 'hcp180_L_VMV1', 'hcp180_R_VMV1'};
ROI_keys{2} = {'hcp180_L_V2', 'hcp180_R_V2', 'hcp180_L_VMV2', 'hcp180_R_VMV2'};
ROI_keys{3} = {'hcp180_L_V3A', 'hcp180_L_V3B', 'hcp180_L_V3', 'hcp180_L_VMV3', ...
    'hcp180_L_V3CD', 'hcp180_R_V3A', 'hcp180_R_V3B', 'hcp180_R_V3', 'hcp180_R_VMV3', 'hcp180_R_V3CD'};
ROI_keys{4} = {'hcp180_L_V4', 'hcp180_L_V4t','hcp180_R_V4', 'hcp180_R_V4t'};
ROI_keys{5} = {'hcp180_L_LO1', 'hcp180_L_LO2','hcp180_L_LO3', 'hcp180_R_LO1', 'hcp180_R_LO2','hcp180_R_LO3'};
ROI_keys{6} = {'hcp180_L_FFC', 'hcp180_R_FFC'};
ROI_keys{7} = {'hcp180_L_PHA1', 'hcp180_L_PHA2','hcp180_L_PHA3', 'hcp180_R_PHA1', 'hcp180_R_PHA2','hcp180_R_PHA3'};
ROI_keys{8} = {'hcp180_L_LO1', 'hcp180_L_LO2','hcp180_L_LO3', 'hcp180_R_LO1', 'hcp180_R_LO2','hcp180_R_LO3',...
    'hcp180_L_FFC', 'hcp180_R_FFC', ...
    'hcp180_L_PHA1', 'hcp180_L_PHA2','hcp180_L_PHA3', 'hcp180_R_PHA1', 'hcp180_R_PHA2','hcp180_R_PHA3'};

ROI_keys{9} =  {'hcp180_L_V1', 'hcp180_R_V1', 'hcp180_L_VMV1', 'hcp180_R_VMV1',...
    'hcp180_L_V2', 'hcp180_R_V2', 'hcp180_L_VMV2', 'hcp180_R_VMV2', ...
    'hcp180_L_V3A', 'hcp180_L_V3B', 'hcp180_L_V3', 'hcp180_L_VMV3', ...
    'hcp180_L_V3CD', 'hcp180_R_V3A', 'hcp180_R_V3B', 'hcp180_R_V3', 'hcp180_R_VMV3', 'hcp180_R_V3CD'};

ROI_keys{10} = {'VC'}

% % Reading probability labels

labels_sh = load('/home/svafaee/Codes/fMRI/EmotionHorikawaCowenKeltner/11988351/data/feature/category.mat');
labels_sh = labels_sh.L.feat;

% % Reading brain data and start decoding 


for i=1:n_Subjects
    brain_data_roi = []
    for j=1:length(ROIname)
        
        subject_name = ['Subject' int2str(i)];
        brain_data_tmp = [];
        
        for k=1:length(ROI_keys{j})
            roi_filename = [subject_name  '_'  ROI_keys{j}{k}  '.mat'];
            brain_data_tmp = load(fullfile(data_path, subject_name, 'rois', roi_filename));
            brain_data_roi = [brain_data_roi brain_data_tmp.braindat];
%            display(size(brain_data_tmp));
        end
        display(size(brain_data_roi));
        
        %Retrieving todays date

        todaysdate = '20210910';
        
        todaysdirectory = ['./results_' todaysdate '/results_' tag4version];
        
        if  ~exist(todaysdirectory, 'dir')
            mkdir(todaysdirectory)
            
        end
        
        filename2save=[todaysdirectory '/resultsDecodingAnalysis_' tag4version '_subject' subject_name '_ROI' ROIname{j} '.mat'];
        display(filename2save)
        results=[];
        predictedLabel=[];
        trueLabel=[];
        
        %% Not checked from here!!!
        if exist(filename2save)==2
            %If the results file for this ROI is already created, skip this ROI
            %and go to the next ROI.
            display(['Subject ' subject_name 'ROI ' ROIname{index_ROIname} ' skipped.'])
        else
            %Save the empty file first.
            save(filename2save,'results')
            %Extract voxel values as a matrix.
            %[feature indices]=select_feature(dataSet,metadata,ROIkeys{index_ROIname});
            feature = brain_data_roi;
            %Extract corresponsing labels (emotion scores).
            %label=get_dataset(dataSet,metadata,'Label');
            %label = get_dataset(dataSet_l, metadata_l, 'Label');
            label = labels_sh;
            %It seems that the first column is 1, second column is stimulus ID,  3-36th clumns are emotion scores.
            %We use 3-36th columns as the variable to be predicted in the
            %decoding analysis.
            %label=label(:,3:36);   %first appro
            %{  
            %secodng approach, fixme
            SecondColumn = label(:, 2);
            feature = [SecondColumn feature];
            display('size of feature');
            display(size(feature));
            label = [SecondColumn label];
            display(size(label));
            feature = sortrows(feature);
            label = sortrows(label);
            feature(:, 1) = [];
            label(:, 1) = [];
            label=label(:,3:36); 
            %}
            
            
            %feature = feature(1:2185, :); %20210910
            %label = label(1:2185, :); %20210910
            
            duplicate_ids = [1,4:8,11,859,866,1673,2157,2187,2188,2194,2195];
            feature(duplicate_ids, :) = [];
            label(duplicate_ids, :) = [];
            %Apply my function to recover count data 
            %(# of positive responses and # of the raters for each stimulus)
            %from the emotion scores.
            [k m]=recoverCountDataFromScores_v1(label);
            
            cvIndex=make_cvindex(rem(1:size(feature,1),10)+1);
            for index_emotion=1:size(label,2)
                for index_lambda=1:length(lambda2)
                    for index_fold=1:length(cvIndex)
                        display(['Subject:' subject_name])
                        display(['ROI:' ROIname{j}])
                        display(['Emotion #:' num2str(index_emotion)])
                        display(['lambda:' num2str(lambda(index_lambda)) ' (' num2str(index_lambda) '/' num2str(length(lambda)) ')'])
                        display(['Fold #:' num2str(index_fold)])
                        tic
                        %Divide the fMRI and label data into training and test data.
                        feature4training=feature(cvIndex(index_fold).trainInds,:);
                        label4training=label(cvIndex(index_fold).trainInds,index_emotion);
                        feature4test=feature(cvIndex(index_fold).testInds,:);
                        label4test=label(cvIndex(index_fold).testInds,index_emotion);
                        %Also, divide the count label data into training and test data.
                        k4training=k(cvIndex(index_fold).trainInds,index_emotion);
                        k4test=k(cvIndex(index_fold).testInds,index_emotion);
                        m4training=m(cvIndex(index_fold).trainInds,1);
                        m4test=m(cvIndex(index_fold).testInds,1);

                        [feature4training mu SD]=zscore(feature4training,1,1);
                        feature4test=(feature4test-ones(size(feature4test,1),1)*mu)./(ones(size(feature4test,1),1)*SD);
            
                        %Model training. The model is cdtSPR with L2-regularization.
                        model=cdtLRtrain_v1_nestedCV(feature4training,k4training,m4training,lambda, 1.0);

                        display(['Best lambda by nested-CV:' num2str(model.FitInfo.Lambda)])
                        %Prediction
                        temporal_predictedLabel=cdtLRpredict_v1(feature4test,model);
                        temporal_trueLabel=label4test;
                
                        %Store the predicted and true values.
                        predictedLabel(cvIndex(index_fold).testInds,index_emotion,index_lambda)=...
                            temporal_predictedLabel;
                        trueLabel(cvIndex(index_fold).testInds,index_emotion,index_lambda)=...
                            temporal_trueLabel;
                        toc
                    end
                    %store and save the results
                    results.trueLabel=trueLabel;
                    results.predictedLabel=predictedLabel;
                    results.corr(index_emotion,index_lambda)=corr(trueLabel(:,index_emotion,index_lambda),predictedLabel(:,index_emotion,index_lambda));
                    save(filename2save,'results','lambda','-v7.3')
                end
            end
            
        end
    end
end
