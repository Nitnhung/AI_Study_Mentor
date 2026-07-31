package com.mentor.backend.service;

import com.mentor.backend.dto.QuizDTO;
import com.mentor.backend.entity.Question;
import com.mentor.backend.entity.Quiz;
import com.mentor.backend.entity.Subject;
import com.mentor.backend.entity.User;
import com.mentor.backend.repository.QuestionRepository;
import com.mentor.backend.repository.QuizRepository;
import com.mentor.backend.repository.SubjectRepository;
import com.mentor.backend.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;
// Đã xóa import UUID

@Service
public class QuizServiceImpl implements QuizService {

    @Autowired
    private QuizRepository quizRepository;

    @Autowired
    private SubjectRepository subjectRepository;

    @Autowired
    private UserRepository userRepository;

    @Override
    public QuizDTO createQuiz(QuizDTO quizDTO) {
        Subject subject = subjectRepository.findById(quizDTO.getSubjectId())
                .orElseThrow(() -> new RuntimeException("Không tìm thấy Subject với ID: " + quizDTO.getSubjectId()));

        User user = userRepository.findById(quizDTO.getUserId())
                .orElseThrow(() -> new RuntimeException("Không tìm thấy User với ID: " + quizDTO.getUserId()));

        Quiz quiz = new Quiz();
        quiz.setQuizId(java.util.UUID.randomUUID().toString());
        quiz.setSubject(subject);
        quiz.setUser(user);
        quiz.setTitle(quizDTO.getTitle());
        quiz.setDescription(quizDTO.getDescription());
        quiz.setTotalScore(quizDTO.getTotalScore()); // Sử dụng totalScore

        Quiz savedQuiz = quizRepository.save(quiz);
        return mapToDTO(savedQuiz);
    }

    @Override
    public QuizDTO getQuizById(String quizId) { // Sửa thành String
        Quiz quiz = quizRepository.findById(quizId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy Quiz với ID: " + quizId));
        return mapToDTO(quiz);
    }

    @Override
    public List<QuizDTO> getAllQuizzes() {
        return quizRepository.findAll().stream()
                .map(this::mapToDTO)
                .collect(Collectors.toList());
    }

    @Override
    public List<QuizDTO> getQuizzesBySubjectId(String subjectId) { // Sửa thành String
        return quizRepository.findBySubject_SubjectId(subjectId).stream()
                .map(this::mapToDTO)
                .collect(Collectors.toList());
    }

    @Autowired
    private QuestionRepository questionRepository;

    @Override
    public List<com.mentor.backend.dto.QuestionDTO> getQuestionsByQuiz(String quizId) { // Sửa thành String
        Quiz quiz = quizRepository.findById(quizId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy Quiz với ID này"));

        return questionRepository.findQuestionsByQuizId(quizId).stream()
                .map(question -> new com.mentor.backend.dto.QuestionDTO(
                        question.getQuestionId(),
                        question.getUser().getUserId(), // Đã xóa .toString()
                        question.getSubject().getSubjectId(),
                        question.getQuestionText(),
                        question.getImageUrl(),

                        question.getOptionA(),
                        question.getOptionB(),
                        question.getOptionC(),
                        question.getOptionD(),
                        question.getCorrectAnswer(),

                        question.getCreatedAt()
                )).collect(Collectors.toList());
    }

    @Override
    public QuizDTO updateQuiz(String quizId, QuizDTO quizDTO) { // Sửa thành String
        Quiz quiz = quizRepository.findById(quizId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy Quiz với ID: " + quizId));

        quiz.setTitle(quizDTO.getTitle());
        quiz.setDescription(quizDTO.getDescription());
        quiz.setTotalScore(quizDTO.getTotalScore());

        // Nếu có truyền subjectId mới thì cập nhật môn học
        if (quizDTO.getSubjectId() != null && !quizDTO.getSubjectId().equals(quiz.getSubject().getSubjectId())) {
            Subject subject = subjectRepository.findById(quizDTO.getSubjectId())
                    .orElseThrow(() -> new RuntimeException("Không tìm thấy Subject"));
            quiz.setSubject(subject);
        }

        Quiz updatedQuiz = quizRepository.save(quiz);
        return mapToDTO(updatedQuiz);
    }

    @Override
    public void deleteQuiz(String quizId) { // Sửa thành String
        if (!quizRepository.existsById(quizId)) {
            throw new RuntimeException("Không tìm thấy Quiz với ID: " + quizId);
        }
        quizRepository.deleteById(quizId);
    }

    // Hàm phụ trợ để chuyển đổi từ Entity sang DTO
    private QuizDTO mapToDTO(Quiz quiz) {
        QuizDTO dto = new QuizDTO();
        dto.setQuizId(quiz.getQuizId());
        dto.setSubjectId(quiz.getSubject().getSubjectId());
        dto.setUserId(quiz.getUser().getUserId());
        dto.setTitle(quiz.getTitle());
        dto.setDescription(quiz.getDescription());
        dto.setTotalScore(quiz.getTotalScore());
        dto.setCreatedAt(quiz.getCreatedAt());
        dto.setUpdatedAt(quiz.getUpdatedAt());
        return dto;
    }
}