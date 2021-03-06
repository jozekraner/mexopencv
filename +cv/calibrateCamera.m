%CALIBRATECAMERA  Finds the camera intrinsic and extrinsic parameters from several views of a calibration pattern
%
%    [cameraMatrix, distCoeffs, reprojErr] = cv.calibrateCamera(objectPoints, imagePts, imageSize)
%    [cameraMatrix, distCoeffs, reprojErr, rvecs, tvecs] = cv.calibrateCamera(...)
%    [...] = cv.calibrateCamera(..., 'OptionName', optionValue, ...)
%
% ## Input
% * __objectPoints__ A cell array of cells of calibration pattern points in
%       the calibration pattern coordinate space `{{[x,y,z], ..}, ...}`. The
%       outer vector contains as many elements as the number of the pattern
%       views. If the same calibration pattern is shown in each view and it is
%       fully visible, all the vectors will be the same. Although, it is
%       possible to use partially occluded patterns, or even different
%       patterns in different views. Then, the vectors will be different. The
%       points are 3D, but since they are in a pattern coordinate system,
%       then, if the rig is planar, it may make sense to put the model to a XY
%       coordinate plane so that Z-coordinate of each input object point is 0.
% * __imagePoints__ A cell array of cells of the projections of calibration
%       pattern points `{{[x,y], ..}, ...}`. `numel(imagePoints)` and
%       `numel(objectPoints)` must be equal, and `numel(imagePoints{i})` must
%       be equal to `numel(objectPoints{i})` for each `i`.
% * __imageSize__ Size of the image used only to initialize the intrinsic
%       camera matrix `[w,h]`.
%
% ## Output
% * __cameraMatrix__ Output 3x3 floating-point camera matrix
%       `A = [fx 0 cx; 0 fy cy; 0 0 1]`
% * __distCoeffs__ Output vector of distortion coefficients
%       `[k1,k2,p1,p2,k3,k4,k5,k6,s1,s2,s3,s4,taux,tauy]` of 4, 5, 8, 12 or 14
%       elements.
% * __reprojErr__ Output final re-projection error.
% * __rvecs__ Output cell array of rotation vectors (see cv.Rodrigues)
%       estimated for each pattern view (cell array of 3-element vectors).
%       That is, each k-th rotation vector together with the corresponding
%       k-th translation vector (see the next output parameter description)
%       brings the calibration pattern from the model coordinate space (in
%       which object points are specified) to the world coordinate space,
%       that is, a real position of the calibration pattern in the k-th
%       pattern view (`k=1:M`)
% * __tvecs__ Output cell array of translation vectors estimated for each
%       pattern view (cell array of 3-element vectors).
%
% ## Options
% * __CameraMatrix__ Input 3x3 camera matrix used as initial value for
%       `cameraMatrix`. If 'UseIntrinsicGuess' and/or 'FixAspectRatio' are
%       specified, some or all of `fx`, `fy`, `cx`, `cy` must be initialized
%       before calling the function. Not set by default (uses `eye(3)`).
% * __DistCoeffs__ Input 4, 5, 8, 12 or 14 elements vector used as an initial
%       values of `distCoeffs`. Not set by default (uses `zeros(1,14)`).
% * __UseIntrinsicGuess__ Logical flag. When true, `CameraMatrix` contains
%       valid initial values of `fx`, `fy`, `cx`, `cy` that are optimized
%       further. Otherwise, `(cx,cy)` is initially set to the image center
%       (`imageSize` is used), and focal distances are computed in a
%       least-squares fashion. Note, that if intrinsic parameters are known,
%       there is no need to use this function just to estimate extrinsic
%       parameters. Use cv.solvePnP instead. default false.
% * __FixPrincipalPoint__ Logical flag. The principal point is not changed
%       during the global optimization. It stays at the center or at a
%       different location specified when 'UseIntrinsicGuess' is set too.
%       default false.
% * __FixAspectRatio__ Logical flag. The functions considers only `fy` as a
%       free parameter. The ratio `fx/fy` stays the same as in the input
%       `CameraMatrix`. When 'UseIntrinsicGuess' is not set, the actual input
%       values of `fx` and `fy` are ignored, only their ratio is computed and
%       used further. default false.
% * __ZeroTangentDist__ Logical flag. Tangential distortion coefficients
%       `p1` and `p2` are set to zeros and stay zero. default false.
% * __FixK1__, ..., __FixK6__ Logical flag. The corresponding radial
%       distortion coefficient is not changed during the optimization. If
%       'UseIntrinsicGuess' is set, the coefficient from the supplied
%       `DistCoeffs` matrix is used. Otherwise, it is set to 0. default false.
% * __RationalModel__ Logical flag. Coefficients `k4`, `k5`, and `k6` are
%       enabled. To provide the backward compatibility, this extra flag should
%       be explicitly specified to make the calibration function use the
%       rational model and return 8 coefficients. If the flag is not set, the
%       function computes and returns only 5 distortion coefficients.
%       default false.
% * __ThinPrismModel__ Logical flag. Coefficients `s1`, `s2`, `s3` and `s4`
%       are enabled. To provide the backward compatibility, this extra flag
%       should be explicitly specified to make the calibration function use
%       the thin prism model and return 12 coefficients. If the flag is not
%       set, the function computes and returns only 5 distortion coefficients.
%       default false.
% * __FixS1S2S3S4__ Logical flag. The thin prism distortion coefficients are
%       not changed during the optimization. If 'UseIntrinsicGuess' is set,
%       the coefficient from the supplied `DistCoeffs` matrix is used.
%       Otherwise, it is set to 0. default false.
% * __TiltedModel__ Coefficients `tauX` and `tauY` are enabled. To provide the
%       backward compatibility, this extra flag should be explicitly specified
%       to make the calibration function use the tilted sensor model and
%       return 14 coefficients. If the flag is not set, the function computes
%       and returns only 5 distortion coefficients. default false.
% * __FixTauXTauY__ The coefficients of the tilted sensor model are not
%       changed during the optimization. If `UseIntrinsicGuess` is set, the
%       coefficient from the supplied `DistCoeffs` matrix is used. Otherwise,
%       it is set to 0. default false.
% * __UseLU__ Use LU instead of SVD decomposition for solving. Much faster but
%       potentially less precise. default false.
% * __Criteria__ Termination criteria for the iterative optimization algorithm.
%       default `struct('type','Count+EPS', 'maxCount',30, 'epsilon',eps)`
%
% The function estimates the intrinsic camera parameters and extrinsic
% parameters for each of the views. The algorithm is based on [Zhang2000] and
% [BoughuetMCT]. The coordinates of 3D object points and their corresponding
% 2D projections in each view must be specified. That may be achieved by using
% an object with a known geometry and easily detectable feature points. Such
% an object is called a calibration rig or calibration pattern, and OpenCV has
% built-in support for a chessboard as a calibration rig (see
% cv.findChessboardCorners). Currently, initialization of intrinsic parameters
% (when 'UseIntrinsicGuess' is not set) is only implemented for planar
% calibration patterns (where Z-coordinates of the object points must be all
% zeros). 3D calibration rigs can also be used as long as initial
% `CameraMatrix` is provided.
%
% The algorithm performs the following steps:
%
%   1. Compute the initial intrinsic parameters (the option only available for
%      planar calibration patterns) or read them from the input parameters.
%      The distortion coefficients are all set to zeros initially unless some
%      of 'FixK?' are specified.
%   2. Estimate the initial camera pose as if the intrinsic parameters have
%      been already known. This is done using cv.solvePnP.
%   3. Run the global Levenberg-Marquardt optimization algorithm to minimize
%      the reprojection error, that is, the total sum of squared distances
%      between the observed feature points `imagePoints` and the projected
%      (using the current estimates for camera parameters and the poses)
%      object points `objectPoints`. See cv.projectPoints for details.
%
% ## Note
% If you use a non-square (=non-NxN) grid and cv.findChessboardCorners for
% calibration, and cv.calibrateCamera returns bad values (zero distortion
% coefficients, an image center very far from `(w/2-0.5,h/2-0.5)`, and/or
% large differences between `fx` and `fy` (ratios of 10:1 or more), then you
% have probably used `patternSize=[rows,cols]` instead of using
% `patternSize=[cols,rows]` in cv.findChessboardCorners.
%
% ## References
% [Zhang2000]:
% > Zhengyou Zhang. "A flexible new technique for camera calibration".
% > Pattern Analysis and Machine Intelligence, IEEE Transactions on,
% > 22(11):1330-1334, 2000.
%
% [BoughuetMCT]:
% > Jean-Yves Bouguet. "Camera calibration toolbox for matlab" [eb/ol], 2004.
%
% See also: cv.findChessboardCorners, cv.solvePnP, cv.initCameraMatrix2D,
%  cv.stereoCalibrate, cv.undistort, estimateCameraParameters, extrinsics
%
